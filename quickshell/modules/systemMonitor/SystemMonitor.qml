pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    property bool open: false
    property bool closing: false
    property bool revealed: false
    readonly property bool visibleState: open || closing

    function toggle() {
        if (open)
            close();
        else
            show();
    }

    function show() {
        closing = false;
        open = true;
        revealed = false;
        revealTimer.restart();
    }

    function close() {
        if (!open && !closing)
            return;

        revealed = false;
        open = false;
        closing = true;
        closeTimer.restart();
    }

    Loader {
        active: root.visibleState
        sourceComponent: Variants {
            model: Quickshell.screens

            SystemMonitorWindow {
                required property ShellScreen modelData

                screen: modelData
                monitor: root
            }
        }
    }

    IpcHandler {
        target: "systemMonitor"

        function toggle(): void {
            root.toggle();
        }

        function show(): void {
            root.show();
        }

        function close(): void {
            root.close();
        }
    }

    Timer {
        id: revealTimer
        interval: 1
        onTriggered: root.revealed = true
    }

    Timer {
        id: closeTimer
        interval: 260
        onTriggered: root.closing = false
    }

    GlobalShortcut {
        name: "systemMonitorToggle"
        description: "Toggle system monitor"
        onPressed: root.toggle()
    }
}
