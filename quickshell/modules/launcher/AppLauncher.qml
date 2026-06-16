import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../launcher/LauncherWindow.qml"

Scope {
    id: root

    property bool open: false
    property bool closing: false
    property real revealProgress: 0
    readonly property bool revealed: revealProgress >= 0.999
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
        revealAnimation.duration = Math.max(1, 260 * (1 - revealProgress));
        revealAnimation.start();
    }

    function close() {
        if (closing || !open)
            return;

        revealAnimation.stop();
        open = false;
        closing = true;
        revealAnimation.to = 0;
        revealAnimation.duration = Math.max(1, 260 * revealProgress);
        revealAnimation.start();
    }

    LauncherModel {
        id: launcherData
    }

    Loader {
        active: root.visibleState
        sourceComponent: LauncherWindow {
            dataModel: launcherData
            launcher: root
        }
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        duration: 260
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

    GlobalShortcut {
        name: "applauncherToggle"
        description: "Toggle app launcher"
        onPressed: root.toggle()
    }
}
