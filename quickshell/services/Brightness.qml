pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real value: 0
    property bool available: false
    property bool hasBrightnessCtl: false
    signal changedByUser

    function refresh() {
        if (!hasBrightnessCtl) {
            available = false;
            return;
        }
        if (readProc.running)
            return;

        readProc.running = false;
        readProc.command = ["brightnessctl", "-m"];
        readProc.running = true;
    }

    function setValue(nextValue) {
        if (!hasBrightnessCtl)
            return;

        const percent = Math.max(1, Math.min(100, Math.round(nextValue * 100)));
        root.value = percent / 100;
        setProc.running = false;
        setProc.command = ["brightnessctl", "-e4", "-n2", "set", `${percent}%`];
        setProc.running = true;
        changedByUser();
    }

    function increase() {
        setValue(value + 0.05);
    }

    function decrease() {
        setValue(value - 0.05);
    }

    Process {
        id: commandCheckProc

        command: ["sh", "-c", "command -v brightnessctl"]
        running: true
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.hasBrightnessCtl = exitCode === 0;
            root.refresh();
        }
    }

    Process {
        id: readProc

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                const current = parseInt(parts[2] || "0");
                const percentPart = parts.find(part => part.endsWith("%")) || "";
                const maxPart = parts.slice(3).find(part => !part.endsWith("%")) || "";
                const percent = parseInt(percentPart.replace("%", ""));
                const max = parseInt(maxPart || "0");
                root.available = (!isNaN(percent) && percent >= 0) || (max > 0 && !isNaN(current));
                root.value = !isNaN(percent) ? percent / 100 : (max > 0 ? current / max : 0);
            }
        }

        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0)
                root.available = false;
        }
    }

    Process {
        id: setProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: root.refresh()
    }

    Timer {
        interval: 700
        running: root.hasBrightnessCtl
        repeat: true
        onTriggered: root.refresh()
    }
}
