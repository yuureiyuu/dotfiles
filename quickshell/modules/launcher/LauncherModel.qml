import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../services"

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string query: ""
    property var thumbnailMap: ({})
    property var thumbnailQueue: []
    property string pendingThumbnailKey: ""
    property string pendingThumbnailOutput: ""
    property int thumbnailVersion: 0
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string wallpaperDir: `${homeDir}/Pictures/wallpapers`
    readonly property url wallpaperDirUrl: Qt.resolvedUrl(`file://${wallpaperDir}`)
    readonly property string cacheDir: `${Quickshell.env("XDG_CACHE_HOME") || `${homeDir}/.cache`}/quickshell/theme/thumbnails`
    readonly property string thumbnailScriptPath: Quickshell.shellPath("scripts/theme/generate_thumbnail.py")
    readonly property bool wallpaperMode: /^:(w|wal|wall|wallpaper)\b/i.test(query)
    readonly property string wallpaperQuery: wallpaperMode ? query.replace(/^:(w|wal|wall|wallpaper)\b\s*/i, "") : ""
    readonly property string appQuery: wallpaperMode ? "" : query
    readonly property var internalApps: [
        {
            id: "quickshell-system-monitor",
            name: SettingsService.t("System Monitor"),
            genericName: "Resource Monitor",
            comment: SettingsService.t("System and process monitoring"),
            icon: "utilities-system-monitor",
            keywords: ["system", "monitor", "btop", "top", "process", "процессы", "ресурсы"],
            execute: () => Quickshell.execDetached(["bash", "-lc", "qs ipc call systemMonitor toggle >/dev/null 2>&1 || quickshell ipc call systemMonitor toggle >/dev/null 2>&1"])
        }
    ]
    readonly property var allApps: internalApps.concat(Array.from(DesktopEntries.applications.values)).filter((app, index, list) => index === list.findIndex(other => other.id === app.id)).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var filteredApps: allApps.map(app => ({
                score: root.appScore(app, appQuery),
                entry: app
            })).filter(item => item.score >= 0).sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name)).slice(0, 40).map(item => ({
                kind: "app",
                name: item.entry.name,
                description: item.entry.comment || item.entry.genericName || item.entry.id,
                icon: item.entry.icon,
                entry: item.entry
            }))
    readonly property var filteredWallpapers: {
        const items = [];
        const cleanQuery = root.normalize(wallpaperQuery);

        for (let i = 0; i < wallpaperFolder.count; i++) {
            const path = wallpaperFolder.get(i, "filePath") || "";
            const fileUrl = wallpaperFolder.get(i, "fileURL") || wallpaperFolder.get(i, "fileUrl") || Qt.resolvedUrl(`file://${path}`);
            const name = wallpaperFolder.get(i, "fileName") || path.split("/").pop();
            if (cleanQuery.length && !root.normalize(name).includes(cleanQuery))
                continue;

            items.push({
                kind: "wallpaper",
                name: name,
                description: path,
                filePath: path,
                fileUrl: fileUrl
            });
        }

        return items;
    }
    readonly property var filteredModel: wallpaperMode ? filteredWallpapers : filteredApps

    function normalize(text) {
        return (text || "").toLowerCase().trim();
    }

    function appScore(entry, searchQuery) {
        const q = normalize(searchQuery);
        if (!q.length)
            return 100000;

        const haystacks = [entry.name || "", entry.genericName || "", entry.comment || "", entry.id || "", (entry.keywords || []).join(" "),];

        let best = -1;
        for (const haystack of haystacks) {
            const idx = normalize(haystack).indexOf(q);
            if (idx === -1)
                continue;

            const score = haystack === (entry.name || "") ? 1000 - idx : 500 - idx;
            if (score > best)
                best = score;
        }

        return best;
    }

    function escapeForShell(value) {
        return `'${String(value).replace(/'/g, `'\\''`)}'`;
    }

    function thumbnailOutputPath(name) {
        const safeName = String(name || "wallpaper").replace(/[^A-Za-z0-9._-]/g, "_");
        return `${cacheDir}/${safeName}.png`;
    }

    function ensureThumbnail(path, name) {
        if (!path)
            return "";

        const cached = thumbnailMap[path];
        if (cached)
            return cached;

        const outputPath = thumbnailOutputPath(name);
        const queueKey = `${path}::${outputPath}`;
        if (thumbnailQueue.indexOf(queueKey) === -1)
            thumbnailQueue = thumbnailQueue.concat([queueKey]);

        startThumbnailJob();
        return "";
    }

    function startThumbnailJob() {
        if (thumbnailProc.running || thumbnailQueue.length === 0)
            return;

        const next = thumbnailQueue[0].split("::");
        pendingThumbnailKey = next[0];
        pendingThumbnailOutput = next[1];
        thumbnailProc.command = ["python3", thumbnailScriptPath, pendingThumbnailKey, pendingThumbnailOutput, "320", "180"];
        thumbnailProc.running = true;
    }

    function launchApp(entry) {
        if (!entry)
            return;

        entry.execute();
    }

    function applyWallpaper(path) {
        if (!path)
            return;

        Theme.applyWallpaper(path);
    }

    FolderListModel {
        id: wallpaperFolder

        folder: root.wallpaperDirUrl
        showDirs: false
        showDotAndDotDot: false
        showHidden: false
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif"]
        sortField: FolderListModel.Name
    }

    Process {
        id: thumbnailProc

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            if (thumbnailQueue.length > 0)
                thumbnailQueue = thumbnailQueue.slice(1);

            if (exitCode === 0 && pendingThumbnailKey.length && pendingThumbnailOutput.length) {
                const updated = Object.assign({}, thumbnailMap);
                updated[pendingThumbnailKey] = `file://${pendingThumbnailOutput}?v=${thumbnailVersion + 1}`;
                thumbnailMap = updated;
                thumbnailVersion += 1;
            }

            pendingThumbnailKey = "";
            pendingThumbnailOutput = "";
            startThumbnailJob();
        }
    }
}
