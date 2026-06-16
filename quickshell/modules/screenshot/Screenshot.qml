pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    property bool open: false
    property bool closing: false
    readonly property bool visibleState: open || closing

    function show() {
        if (open && !closing)
            return;

        closing = false;
        open = true;
    }

    function close() {
        if (!open && !closing)
            return;

        closing = true;
        closeTimer.restart();
    }

    Loader {
        active: root.visibleState
        sourceComponent: Variants {
            model: Quickshell.screens

            ScreenshotWindow {
                required property ShellScreen modelData

                screen: modelData
                screenshot: root
            }
        }
    }

    IpcHandler {
        target: "screenshot"

        function open(): void {
            root.show();
        }

        function close(): void {
            root.close();
        }
    }

    Timer {
        id: closeTimer

        interval: 220
        repeat: false
        onTriggered: {
            root.open = false;
            root.closing = false;
        }
    }

    GlobalShortcut {
        name: "screenshot"
        description: "Select an area and save screenshot to Pictures and clipboard"
        onPressed: root.show()
    }
}
