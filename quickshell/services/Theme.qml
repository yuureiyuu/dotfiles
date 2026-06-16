pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateRoot: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/quickshell/theme`
    readonly property string paletteFilePath: `${stateRoot}/palette.json`
    readonly property string wallpaperFilePath: `${stateRoot}/current-wallpaper`
    readonly property string modeFilePath: `${stateRoot}/mode`
    readonly property string applyScriptPath: Quickshell.shellPath("scripts/theme/apply_wallpaper.sh")
    readonly property string extractScriptPath: Quickshell.shellPath("scripts/theme/extract_palette.py")
    readonly property string applyTargetsScriptPath: Quickshell.shellPath("scripts/theme/apply_targets.sh")

    property string currentWallpaper: ""
    property string baseHex: "#24273a"
    property string mantleHex: "#1e2030"
    property string surfaceHex: "#363a4f"
    property string surface2Hex: "#494d64"
    property string textHex: "#cad3f5"
    property string subtextHex: "#939ab7"
    property string accentHex: "#8aadf4"
    property string accent2Hex: "#c6a0f6"
    property string borderHex: "#494d64"
    property string swatch0: "#8aadf4"
    property string swatch1: "#c6a0f6"
    property string swatch2: "#cad3f5"
    property string swatch3: "#939ab7"
    property string swatch4: "#494d64"
    property string swatch5: "#363a4f"
    property string swatch6: "#24273a"
    property string swatch7: "#1e2030"
    property bool darkMode: true
    property color base: root.baseHex
    property color mantle: root.mantleHex
    property color surface: root.surfaceHex
    property color surface2: root.surface2Hex
    property color text: root.textHex
    property color subtext: root.subtextHex
    property color accent: root.accentHex
    property color accent2: root.accent2Hex
    property color border: root.borderHex
    property color icon: root.mixColor(root.text, root.accent, 0.18)
    property color iconMuted: root.mixColor(root.subtext, root.accent, 0.10)
    property color iconActive: root.mixColor(root.text, root.accent, 0.34)
    property color barIcon: root.darkMode ? root.mixColor(root.text, root.accent, 0.12) : root.text
    property color barIconMuted: Qt.alpha(root.barIcon, 0.72)
    property color barIconActive: root.darkMode ? root.mixColor(root.text, root.accent, 0.18) : root.text
    property var darkPalette: ({})
    property var lightPalette: ({})

    function applyDarkMode(enabled, syncExternal) {
        darkMode = enabled;
        const palette = enabled ? darkPalette : lightPalette;
        applyPaletteObject(palette && Object.keys(palette).length ? palette : defaultPalette(enabled));
        if (syncExternal !== false)
            applyTargets();
    }

    function defaultPalette(dark) {
        return dark ? {
            base: "#24273a", mantle: "#1e2030", surface: "#363a4f", surface2: "#494d64",
            text: "#cad3f5", subtext: "#939ab7", accent: "#8aadf4", accent2: "#c6a0f6",
            border: "#494d64", colors: ["#8aadf4", "#c6a0f6", "#cad3f5", "#939ab7", "#494d64", "#363a4f", "#24273a", "#1e2030"]
        } : {
            base: "#eff1f5", mantle: "#e6e9ef", surface: "#ccd0da", surface2: "#bcc0cc",
            text: "#4c4f69", subtext: "#6c6f85", accent: "#1e66f5", accent2: "#8839ef",
            border: "#bcc0cc", colors: ["#1e66f5", "#8839ef", "#4c4f69", "#6c6f85", "#bcc0cc", "#ccd0da", "#eff1f5", "#e6e9ef"]
        };
    }

    function toggleMode() {
        applyDarkMode(!darkMode);
    }

    function applyPaletteObject(data) {
        if (!data)
            return;

        root.baseHex = data.base || root.baseHex;
        root.mantleHex = data.mantle || root.mantleHex;
        root.surfaceHex = data.surface || root.surfaceHex;
        root.surface2Hex = data.surface2 || root.surface2Hex;
        root.textHex = data.text || root.textHex;
        root.subtextHex = data.subtext || root.subtextHex;
        root.accentHex = data.accent || root.accentHex;
        root.accent2Hex = data.accent2 || root.accent2Hex;
        root.borderHex = data.border || root.borderHex;
        const colors = Array.isArray(data.colors) && data.colors.length >= 8 ? data.colors : [root.accentHex, root.accent2Hex, root.textHex, root.subtextHex, root.surface2Hex, root.surfaceHex, root.baseHex, root.mantleHex];
        root.swatch0 = colors[0];
        root.swatch1 = colors[1];
        root.swatch2 = colors[2];
        root.swatch3 = colors[3];
        root.swatch4 = colors[4];
        root.swatch5 = colors[5];
        root.swatch6 = colors[6];
        root.swatch7 = colors[7];
    }

    function mixColor(baseColor, tintColor, amount) {
        const ratio = Math.max(0, Math.min(1, amount));
        return Qt.rgba(baseColor.r + (tintColor.r - baseColor.r) * ratio, baseColor.g + (tintColor.g - baseColor.g) * ratio, baseColor.b + (tintColor.b - baseColor.b) * ratio, baseColor.a + (tintColor.a - baseColor.a) * ratio);
    }

    function colorToHex(value) {
        const r = Math.round(value.r * 255).toString(16).padStart(2, "0");
        const g = Math.round(value.g * 255).toString(16).padStart(2, "0");
        const b = Math.round(value.b * 255).toString(16).padStart(2, "0");
        return `#${r}${g}${b}`;
    }

    function lightPaletteFromDark(data) {
        const accent = Qt.color(data.accent || root.accentHex);
        const accent2 = Qt.color(data.accent2 || root.accent2Hex);
        return {
            base: root.colorToHex(root.mixColor(Qt.color("#eff1f5"), accent, 0.05)),
            mantle: root.colorToHex(root.mixColor(Qt.color("#e6e9ef"), accent, 0.04)),
            surface: root.colorToHex(root.mixColor(Qt.color("#ccd0da"), accent, 0.07)),
            surface2: root.colorToHex(root.mixColor(Qt.color("#bcc0cc"), accent, 0.09)),
            text: root.colorToHex(root.mixColor(Qt.color("#4c4f69"), accent, 0.06)),
            subtext: root.colorToHex(root.mixColor(Qt.color("#6c6f85"), accent, 0.08)),
            accent: data.accent || root.accentHex,
            accent2: data.accent2 || root.accent2Hex,
            border: root.colorToHex(root.mixColor(Qt.color("#bcc0cc"), accent2, 0.08)),
            colors: data.colors || []
        };
    }

    function applyPalette(payload) {
        if (!payload || !payload.length)
            return;

        try {
            const data = JSON.parse(payload);
            root.darkPalette = data.dark || data;
            root.lightPalette = data.light || root.lightPaletteFromDark(root.darkPalette);
            root.applyDarkMode(root.darkMode, false);
        } catch (error) {
            console.warn("Failed to parse palette payload", error);
        }
    }

    function applyWallpaper(path) {
        if (!path || !path.length)
            return;

        applyWallpaperProc.targetPath = path;
        applyWallpaperProc.command = [root.applyScriptPath, path];
        applyWallpaperProc.running = true;
    }

    function refreshPalette(path) {
        if (!path || !path.length)
            return;

        extractPaletteProc.command = ["python3", root.extractScriptPath, path, root.paletteFilePath];
        extractPaletteProc.running = true;
    }

    function applyTargets() {
        applyTargetsProc.command = [root.applyTargetsScriptPath, root.darkMode ? "dark" : "light"];
        applyTargetsProc.running = true;
    }

    Process {
        id: applyWallpaperProc

        property string targetPath: ""
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                return;

            root.currentWallpaper = targetPath;
            wallpaperFileView.reload();
            root.refreshPalette(targetPath);
        }
    }

    Process {
        id: extractPaletteProc

        stdout: StdioCollector {
            id: paletteCollector

            onStreamFinished: root.applyPalette(text)
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                paletteFileView.reload();
                root.applyTargets();
            }
        }
    }

    Process {
        id: applyTargetsProc

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    FileView {
        id: paletteFileView

        path: root.paletteFilePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyPalette(text())
    }

    FileView {
        id: modeFileView

        path: root.modeFilePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const mode = text().trim();
            if (mode === "dark" || mode === "light")
                root.applyDarkMode(mode === "dark", false);
        }
    }

    FileView {
        id: wallpaperFileView

        path: root.wallpaperFilePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.currentWallpaper = text().trim();
            if (root.currentWallpaper.length)
                root.refreshPalette(root.currentWallpaper);
        }
    }
}
