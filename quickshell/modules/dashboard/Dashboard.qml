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
        if (closing)
            show();
        else if (open)
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
        if ((!open && !closing) || closing)
            return;

        closing = true;
        revealed = false;
    }

    function finishClose() {
        open = false;
        closing = false;
        revealed = false;
    }

    Loader {
        active: root.visibleState
        sourceComponent: DashboardWindow {
            dashboard: root
        }
    }

    IpcHandler {
        target: "dashboard"

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
        interval: 280
        running: root.closing
        onTriggered: {
            if (root.closing)
                root.finishClose();
        }
    }

    GlobalShortcut {
        name: "dashboardToggle"
        description: "Toggle dashboard"
        onPressed: root.toggle()
    }
}
