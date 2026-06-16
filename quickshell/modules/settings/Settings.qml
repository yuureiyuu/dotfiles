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
        revealAnimation.duration = Math.max(1, SettingsService.duration(240) * (1 - revealProgress));
        revealAnimation.start();
    }

    function close() {
        if (closing || !open)
            return;

        revealAnimation.stop();
        open = false;
        closing = true;
        revealAnimation.to = 0;
        revealAnimation.duration = Math.max(1, SettingsService.duration(220) * revealProgress);
        revealAnimation.start();
    }

    Loader {
        active: root.visibleState
        sourceComponent: SettingsWindow {
            settings: root
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            root.toggle();
        }

        function show(): void {
            root.show();
        }

        function close(): void {
            root.close();
        }

        function setBarPosition(position: string): void {
            SettingsService.setBarPosition(position);
        }

        function setWeatherService(enabled: bool): void {
            SettingsService.weatherService = enabled;
        }

        function setSystemStatsService(enabled: bool): void {
            SettingsService.systemStatsService = enabled;
        }

        function setNowPlayingService(enabled: bool): void {
            SettingsService.nowPlayingService = enabled;
        }

        function setBatteryService(enabled: bool): void {
            SettingsService.batteryService = enabled;
        }

        function setWallpaperDim(enabled: bool): void {
            SettingsService.wallpaperDim = enabled;
        }

        function setDesktopClock(enabled: bool): void {
            SettingsService.desktopClock = enabled;
        }

        function setBackgroundBlur(value: real): void {
            SettingsService.setBackgroundBlur(value);
        }

        function setAnimations(enabled: bool): void {
            SettingsService.animationsEnabled = enabled;
        }

        function setClock24h(enabled: bool): void {
            SettingsService.clock24h = enabled;
        }

        function setIslandEnabled(enabled: bool): void {
            SettingsService.islandEnabled = enabled;
        }

        function setCompactIsland(enabled: bool): void {
            SettingsService.compactIsland = enabled;
        }

        function setInterfaceScale(value: real): void {
            SettingsService.interfaceScale = Math.max(0.75, Math.min(1.25, value));
        }

        function resetGeneral(): void {
            SettingsService.resetGeneral();
        }

        function resetInterface(): void {
            SettingsService.resetInterface();
        }
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggle settings"
        onPressed: root.toggle()
    }

    Process {
        id: hyprBind

        command: ["hyprctl", "keyword", "bind", "$mainMod SHIFT, S, global, quickshell:settingsToggle"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        duration: SettingsService.duration(240)
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
