pragma ComponentBehavior: Bound
pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "."

Singleton {
    id: root

    readonly property bool active: SettingsService.systemStatsService && (LockState.locked || forceActive || refCount > 0)
    property string hostname: ""
    property string username: Quickshell.env("USER") || ""
    property string uptimeText: ""
    property real cpuUsage: 0
    property real memoryUsage: 0
    property real memoryTotalGiB: 0
    property real memoryUsedGiB: 0
    property real swapUsage: 0
    property real swapTotalGiB: 0
    property real diskUsage: 0
    property string diskText: ""
    property string diskMount: "/"
    property real temperature: 0
    property string temperatureText: "N/A"
    property real batteryLevel: Battery.percentage
    property bool batteryCharging: Battery.isCharging
    property bool batteryAvailable: Battery.available
    property real gpuUsage: 0
    property bool gpuDetected: false
    property bool gpuUsageAvailable: false
    property string gpuVendor: ""
    property string gpuName: ""
    property string gpuStatus: ""
    readonly property string gpuDisplayText: gpuUsageAvailable ? `${Math.round(gpuUsage)}%` : "N/A"
    readonly property string memoryDisplayText: `${memoryUsedGiB.toFixed(1)} / ${memoryTotalGiB.toFixed(1)} GiB`
    readonly property string swapDisplayText: swapTotalGiB > 0 ? `${Math.round(swapUsage)}%` : "Off"
    readonly property string batteryDisplayText: batteryAvailable ? `${Math.round(batteryLevel * 100)}%` : "N/A"
    property bool forceActive: false
    property int refCount: 0
    property int historyLimit: 96
    property var cpuUsageHistory: []
    property var memoryUsageHistory: []
    property var gpuUsageHistory: []
    property var networkRxHistory: []
    property var networkTxHistory: []
    property var diskUsageHistory: []
    property var topProcesses: []
    property var processes: []
    property int processCount: 0
    property string lastKillResult: ""
    property real networkRxBytes: 0
    property real networkTxBytes: 0
    property real networkRxRate: 0
    property real networkTxRate: 0
    property string networkInterface: "all"
    property bool networkReady: false

    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property real previousNetworkRxBytes: 0
    property real previousNetworkTxBytes: 0
    property real previousNetworkTimestamp: 0

    function clamp(value) {
        return Math.max(0, Math.min(100, value));
    }

    function retain() {
        root.refCount++;
    }

    function release() {
        root.refCount = Math.max(0, root.refCount - 1);
    }

    function appendHistory(history, value) {
        const next = history.concat([Math.max(0, Number(value) || 0)]);
        if (next.length > root.historyLimit)
            next.shift();
        return next;
    }

    function recordHistory() {
        root.cpuUsageHistory = root.appendHistory(root.cpuUsageHistory, root.cpuUsage);
        root.memoryUsageHistory = root.appendHistory(root.memoryUsageHistory, root.memoryUsage);
        root.gpuUsageHistory = root.appendHistory(root.gpuUsageHistory, root.gpuUsage);
        root.diskUsageHistory = root.appendHistory(root.diskUsageHistory, root.diskUsage);
        root.networkRxHistory = root.appendHistory(root.networkRxHistory, Math.min(100, root.networkRxRate / 1048576 * 12));
        root.networkTxHistory = root.appendHistory(root.networkTxHistory, Math.min(100, root.networkTxRate / 1048576 * 12));
    }

    function formatUptime(seconds) {
        const totalSeconds = Math.max(0, Math.floor(seconds));
        const days = Math.floor(totalSeconds / 86400);
        const hours = Math.floor((totalSeconds % 86400) / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);

        if (days > 0)
            return `${days}d ${hours}h`;
        if (hours > 0)
            return `${hours}h ${minutes}m`;
        return `${minutes}m`;
    }

    function formatBytes(bytes) {
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let value = Math.max(0, Number(bytes) || 0);
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        return `${value.toFixed(unit === 0 ? 0 : 1)} ${units[unit]}`;
    }

    function killProcess(pid, force) {
        const pidText = String(pid || "").trim();
        if (!/^[0-9]+$/.test(pidText))
            return;

        killProc.command = ["kill", force ? "-KILL" : "-TERM", pidText];
        killProc.targetPid = pidText;
        killProc.running = true;
    }

    function refresh() {
        if (!root.active || statsProc.running)
            return;

        statsProc.command = ["bash", "-lc",
            "printf '__HOST__\\n'; hostname; " +
            "printf '__CPU__\\n'; awk 'NR==1 {print $2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7\" \"$8\" \"$9}' /proc/stat; " +
            "printf '__MEM__\\n'; awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} /SwapTotal/ {st=$2} /SwapFree/ {sf=$2} END {print t\" \"a\" \"st\" \"sf}' /proc/meminfo; " +
            "printf '__UPTIME__\\n'; cut -d' ' -f1 /proc/uptime; " +
            "printf '__DISK__\\n'; df -Pk / 2>/dev/null | awk 'NR==2 {printf \"%s %s %s %s %s\\n\", $2, $3, $4, $5, $6}'; " +
            "printf '__NET__\\n'; awk -F'[: ]+' 'NR>2 && $2 != \"lo\" {rx+=$3; tx+=$11; if (iface == \"\") iface=$2} END {printf \"%s %s %s\\n\", rx+0, tx+0, iface}' /proc/net/dev; " +
            "printf '__TEMP__\\n'; awk '{if ($1 > 0 && (min == 0 || $1 < min)) min=$1; if ($1 > max) max=$1} END {if (max > 0) printf \"%.1f\\n\", max/1000; else print \"N/A\"}' /sys/class/thermal/thermal_zone*/temp 2>/dev/null; " +
            "printf '__GPU__\\n'; " +
            "gpu_line=$(lspci 2>/dev/null | grep -iE 'vga|3d controller|display' | head -1); " +
            "gpu_vendor_id=$(cat /sys/class/drm/card*/device/vendor 2>/dev/null | head -1); " +
            "gpu_usage=N/A; gpu_status=unavailable; " +
            "if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then " +
            "gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | awk '{sum+=$1; count++} END {if (count) print sum/count; else print \"N/A\"}'); gpu_status=nvidia-smi; " +
            "elif ls /sys/class/drm/card*/device/gpu_busy_percent >/dev/null 2>&1; then " +
            "gpu_usage=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | awk '{sum+=$1; count++} END {if (count) print sum/count; else print \"N/A\"}'); gpu_status=sysfs; " +
            "elif command -v intel_gpu_top >/dev/null 2>&1; then " +
            "intel_out=$(timeout 2s intel_gpu_top -J -s 1000 -o - 2>&1); if printf '%s' \"$intel_out\" | grep -qi 'permission denied\\|CAP_PERFMON'; then gpu_status='intel_gpu_top needs CAP_PERFMON'; else gpu_status=intel_gpu_top; fi; gpu_usage=$(printf '%s' \"$intel_out\" | awk -F: '/\"busy\"/ {gsub(/[^0-9.]/, \"\", $2); if ($2 > max) max=$2} END {if (max != \"\") print max; else print \"N/A\"}'); " +
            "elif command -v radeontop >/dev/null 2>&1; then " +
            "gpu_usage=$(timeout 2s radeontop -d - -l 1 2>/dev/null | awk -F'gpu ' '/gpu/ {split($2, a, \"%\"); print a[1]; found=1} END {if (!found) print \"N/A\"}'); gpu_status=radeontop; fi; " +
            "printf '%s|%s|%s|%s\\n' \"${gpu_usage:-N/A}\" \"${gpu_vendor_id:-}\" \"${gpu_line:-}\" \"${gpu_status:-unavailable}\"; " +
            "printf '__GPU_PROCS__\\n'; if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits 2>/dev/null | awk -F, '{gsub(/ /, \"\", $1); gsub(/ /, \"\", $2); if ($1 != \"\") print $1\"|\"$2}'; fi; " +
            "printf '__PROCESSES__\\n'; ps -eo pid=,ppid=,stat=,comm=,pcpu=,pmem=,rss=,etime=,args= --sort=-pcpu 2>/dev/null | awk '{pid=$1; ppid=$2; stat=$3; comm=$4; cpu=$5; mem=$6; rss=$7; etime=$8; args=\"\"; for (i=9; i<=NF; i++) args=args (i>9 ? \" \" : \"\") $i; gsub(/\\|/, \" \", args); gsub(/\\|/, \" \", comm); printf \"%s|%s|%s|%s|%s|%s|%s|%s|%s\\n\", pid, ppid, stat, comm, cpu, mem, rss, etime, args}'"
        ];
        statsProc.running = true;
    }

    Process {
        id: statsProc

        stdout: StdioCollector {
            id: statsOut
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            const text = statsOut.text.trim();
            if (!text.length)
                return;

            const lines = text.split("\n");
            const section = name => lines.indexOf(name);
            const lineAfter = name => {
                const index = section(name);
                return index >= 0 && index + 1 < lines.length ? lines[index + 1] : "";
            };

            root.hostname = lineAfter("__HOST__") || root.hostname;

            const cpuParts = lineAfter("__CPU__").trim().split(/\s+/).map(Number);
            if (cpuParts.length >= 4) {
                const total = cpuParts.reduce((sum, value) => sum + value, 0);
                const idle = (cpuParts[3] || 0) + (cpuParts[4] || 0);
                if (root.previousCpuTotal > 0) {
                    const totalDelta = total - root.previousCpuTotal;
                    const idleDelta = idle - root.previousCpuIdle;
                    if (totalDelta > 0)
                        root.cpuUsage = root.clamp((1 - idleDelta / totalDelta) * 100);
                }
                root.previousCpuTotal = total;
                root.previousCpuIdle = idle;
            }

            const memoryParts = lineAfter("__MEM__").trim().split(/\s+/).map(Number);
            if (memoryParts.length >= 2) {
                const totalMemory = memoryParts[0] || 0;
                const availableMemory = memoryParts[1] || 0;
                const swapTotal = memoryParts[2] || 0;
                const swapFree = memoryParts[3] || 0;
                if (totalMemory > 0) {
                    root.memoryUsage = root.clamp((1 - availableMemory / totalMemory) * 100);
                    root.memoryTotalGiB = totalMemory / 1048576;
                    root.memoryUsedGiB = (totalMemory - availableMemory) / 1048576;
                }
                root.swapTotalGiB = swapTotal / 1048576;
                root.swapUsage = swapTotal > 0 ? root.clamp((1 - swapFree / swapTotal) * 100) : 0;
            }

            root.uptimeText = root.formatUptime(Number(lineAfter("__UPTIME__")));

            const diskParts = lineAfter("__DISK__").trim().split(/\s+/);
            if (diskParts.length >= 5) {
                const totalDisk = Number(diskParts[0]) || 0;
                const usedDisk = Number(diskParts[1]) || 0;
                root.diskUsage = totalDisk > 0 ? root.clamp(usedDisk / totalDisk * 100) : 0;
                root.diskText = `${root.formatBytes(usedDisk * 1024)} / ${root.formatBytes(totalDisk * 1024)}`;
                root.diskMount = diskParts[4] || "/";
            }

            const networkParts = lineAfter("__NET__").trim().split(/\s+/);
            if (networkParts.length >= 2) {
                const rx = Number(networkParts[0]) || 0;
                const tx = Number(networkParts[1]) || 0;
                const now = Date.now();
                if (root.previousNetworkTimestamp > 0 && (rx >= root.previousNetworkRxBytes) && (tx >= root.previousNetworkTxBytes)) {
                    const seconds = Math.max(0.001, (now - root.previousNetworkTimestamp) / 1000);
                    root.networkRxRate = (rx - root.previousNetworkRxBytes) / seconds;
                    root.networkTxRate = (tx - root.previousNetworkTxBytes) / seconds;
                    root.networkReady = true;
                }
                root.previousNetworkRxBytes = rx;
                root.previousNetworkTxBytes = tx;
                root.previousNetworkTimestamp = now;
                root.networkRxBytes = rx;
                root.networkTxBytes = tx;
                root.networkInterface = networkParts[2] || "all";
            }

            const tempLine = lineAfter("__TEMP__").trim();
            const tempValue = Number(tempLine);
            root.temperature = Number.isFinite(tempValue) ? tempValue : 0;
            root.temperatureText = Number.isFinite(tempValue) ? `${tempValue.toFixed(0)} C` : "N/A";

            const gpuParts = lineAfter("__GPU__").split("|");
            if (gpuParts.length >= 4) {
                const gpuText = gpuParts[0].trim();
                const gpuValue = Number(gpuText);
                root.gpuUsageAvailable = gpuText.length > 0 && Number.isFinite(gpuValue);
                root.gpuUsage = root.gpuUsageAvailable ? root.clamp(gpuValue) : 0;

                const vendorId = gpuParts[1].trim().toLowerCase();
                if (vendorId === "0x8086")
                    root.gpuVendor = "Intel";
                else if (vendorId === "0x1002")
                    root.gpuVendor = "AMD";
                else if (vendorId === "0x10de")
                    root.gpuVendor = "NVIDIA";
                else if (vendorId.length)
                    root.gpuVendor = vendorId;

                const gpuLine = gpuParts[2].trim();
                root.gpuDetected = gpuLine.length > 0 || root.gpuVendor.length > 0;
                if (gpuLine.length) {
                    const nameMatch = gpuLine.match(/:\s*(.+?)(?:\s+\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\].*)?$/);
                    root.gpuName = nameMatch ? nameMatch[1].replace(/\[[^\]]+\]/g, "").replace(/\s+/g, " ").trim() : gpuLine;
                }
                root.gpuStatus = gpuParts[3].trim();
            }

            const gpuProcessMemory = {};
            const gpuProcessMarker = section("__GPU_PROCS__");
            const processMarker = section("__PROCESSES__");
            if (gpuProcessMarker >= 0) {
                const end = processMarker >= 0 ? processMarker : lines.length;
                for (let i = gpuProcessMarker + 1; i < end; i++) {
                    const parts = lines[i].split("|");
                    if (parts.length >= 2)
                        gpuProcessMemory[parts[0]] = Number(parts[1]) || 0;
                }
            }

            if (processMarker >= 0) {
                const processList = [];
                for (let i = processMarker + 1; i < lines.length; i++) {
                    const parts = lines[i].split("|");
                    if (parts.length < 9)
                        continue;

                    const pid = parts[0];
                    const args = parts.slice(8).join("|").trim();
                    const command = args.length ? args : parts[3];
                    processList.push({
                        pid,
                        ppid: parts[1],
                        state: parts[2],
                        name: parts[3],
                        cpu: Number(parts[4]) || 0,
                        memory: Number(parts[5]) || 0,
                        rssMiB: (Number(parts[6]) || 0) / 1024,
                        runtime: parts[7],
                        command,
                        gpuMemoryMiB: gpuProcessMemory[pid] || 0
                    });
                }
                root.processes = processList;
                root.processCount = processList.length;
                root.topProcesses = processList.slice(0, 8);
            }

            root.recordHistory();
            root.batteryLevel = Battery.percentage;
            root.batteryCharging = Battery.isCharging;
            root.batteryAvailable = Battery.available;
        }
    }

    Process {
        id: killProc

        property string targetPid: ""

        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: killErr
        }

        onExited: (exitCode, exitStatus) => {
            root.lastKillResult = exitCode === 0 ? `Sent signal to ${targetPid}` : (killErr.text.trim() || `Failed to signal ${targetPid}`);
            root.refresh();
        }
    }

    Timer {
        interval: 3000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
