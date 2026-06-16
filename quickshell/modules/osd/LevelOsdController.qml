import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../services"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        LevelOsd {
            required property ShellScreen modelData

            screen: modelData
        }
    }

    IpcHandler {
        target: "audio"

        function volumeUp(): void {
            Audio.increaseVolume();
        }

        function volumeDown(): void {
            Audio.decreaseVolume();
        }

        function mute(): void {
            Audio.setMuted(!Audio.muted);
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            Brightness.increase();
        }

        function down(): void {
            Brightness.decrease();
        }
    }

    GlobalShortcut {
        name: "volumeUp"
        description: "Increase output volume"
        onPressed: Audio.increaseVolume()
    }

    GlobalShortcut {
        name: "volumeDown"
        description: "Decrease output volume"
        onPressed: Audio.decreaseVolume()
    }

    GlobalShortcut {
        name: "volumeMute"
        description: "Mute output volume"
        onPressed: Audio.setMuted(!Audio.muted)
    }

    GlobalShortcut {
        name: "brightnessUp"
        description: "Increase brightness"
        onPressed: Brightness.increase()
    }

    GlobalShortcut {
        name: "brightnessDown"
        description: "Decrease brightness"
        onPressed: Brightness.decrease()
    }
}
