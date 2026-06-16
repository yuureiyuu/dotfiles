pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../services"

Scope {
    id: root

    property bool open: false
    property bool closing: false
    property real revealProgress: 0
    readonly property bool visibleState: open || closing || revealProgress > 0.001

    function toggle() {
        if (open)
            close();
        else
            show();
    }

    function show() {
        if (open && !closing)
            return;

        revealAnimation.stop();
        closing = false;
        open = true;
        revealAnimation.to = 1;
        revealAnimation.duration = Math.max(1, SettingsService.duration(230) * (1 - revealProgress));
        revealAnimation.start();
    }

    function close() {
        if (closing || !open)
            return;

        revealAnimation.stop();
        open = false;
        closing = true;
        revealAnimation.to = 0;
        revealAnimation.duration = Math.max(1, SettingsService.duration(230) * revealProgress);
        revealAnimation.start();
    }

    Loader {
        active: root.visibleState
        sourceComponent: BarPanelWindow {
            panel: root
        }
    }

    IpcHandler {
        target: "barPanel"

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

    GlobalShortcut {
        name: "barPanelToggle"
        description: "Toggle bar panel"
        onPressed: root.toggle()
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        duration: SettingsService.duration(230)
        easing.type: Easing.OutCubic

        onFinished: {
            if (root.revealProgress <= 0.001) {
                root.revealProgress = 0;
                root.closing = false;
            } else if (root.revealProgress >= 0.999) {
                root.revealProgress = 1;
            }
        }
    }
}
