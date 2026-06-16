pragma ComponentBehavior: Bound

import Quickshell
import "./services"
import "./modules/bar/"
import "./modules/session/"
import "./modules/launcher/"
import "./modules/lock/"
import "./modules/systemMonitor/"
import "./modules/island/"
import "./modules/dashboard/"
import "./modules/settings/"
import "./modules/background/"
import "./modules/notifications/"
import "./modules/barPanel/"
import "./modules/osd/"
import "./modules/screenshot/"
import "./modules/hotkeys/"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Background {
            required property ShellScreen modelData

            screen: modelData
        }
    }

    LockScreen {
        id: lockScreen

        onLockedChanged: {
            if (!locked)
                return;

            sessionWidget.visible = false;
            appLauncher.close();
            systemMonitor.close();
            dashboard.close();
            settings.close();
            barPanel.close();
            hotkeys.close();
        }
    }

    Dashboard {
        id: dashboard
    }

    BarPanel {
        id: barPanel
    }

    Settings {
        id: settings
    }

    Hotkeys {
        id: hotkeys
    }

    Sidebar {
        visible: !sessionWidget.visible && !lockScreen.locked && !LockState.pendingLock && !barPanel.visibleState && !settings.visibleState && !hotkeys.visibleState
        onPowerClicked: sessionWidget.toggle()
        onBarPanelClicked: barPanel.toggle()
    }

    Variants {
        model: Quickshell.screens

        NotificationPopups {
            required property ShellScreen modelData

            screen: modelData
        }
    }

    LevelOsdController {}

    Screenshot {}

    AppLauncher {
        id: appLauncher
    }

    SessionWidget {
        id: sessionWidget
    }

    SystemMonitor {
        id: systemMonitor
    }

    Variants {
        model: Quickshell.screens

        BottomIsland {
            required property ShellScreen modelData

            screen: modelData
            appLauncher: appLauncher
            dashboard: dashboard
            settings: settings
            systemMonitor: systemMonitor
            onDashboardClicked: dashboard.toggle()
            onSettingsClicked: settings.toggle()
        }
    }
}
//Quickshell Types: "https://quickshell.org/docs/v0.2.1/types"
//QtQuick Types: "https://doc.qt.io/qt-6/qtquick-qmlmodule.html"
//quickshell shell example1: "https://github.com/caelestia-dots/shell"
//quickshell shell example2: "https://github.com/end-4/dots-hyprland/tree/main/dots/.config/quickshell/ii"
