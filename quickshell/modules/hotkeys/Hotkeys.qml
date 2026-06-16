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
        revealAnimation.duration = Math.max(1, SettingsService.duration(220) * (1 - revealProgress));
        revealAnimation.start();
    }

    function close() {
        if (closing || !open)
            return;

        revealAnimation.stop();
        open = false;
        closing = true;
        revealAnimation.to = 0;
        revealAnimation.duration = Math.max(1, SettingsService.duration(180) * revealProgress);
        revealAnimation.start();
    }

    Loader {
        active: root.visibleState
        sourceComponent: Variants {
            model: Quickshell.screens

            HotkeysWindow {
                required property ShellScreen modelData

                screen: modelData
                hotkeys: root
            }
        }
    }

    IpcHandler {
        target: "hotkeys"

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
        name: "hotkeysToggle"
        description: "Toggle hotkeys overview"
        onPressed: root.toggle()
    }

    Process {
        id: hyprBind

        command: ["hyprctl", "keyword", "bind", "$mainMod SHIFT, H, global, quickshell:hotkeysToggle"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        duration: SettingsService.duration(220)
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

    Component.onCompleted: {
        if ((Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "").length)
            hyprBind.running = true;
    }
}
