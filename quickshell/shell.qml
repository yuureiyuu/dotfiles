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

ShellRoot {
    Background {}

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

    Sidebar {
        visible: !sessionWidget.visible && !lockScreen.locked && !LockState.pendingLock && !barPanel.visibleState && !settings.visibleState
        onPowerClicked: sessionWidget.toggle()
        onBarPanelClicked: barPanel.toggle()
    }

    NotificationPopups {}

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

    BottomIsland {
        appLauncher: appLauncher
        dashboard: dashboard
        settings: settings
        systemMonitor: systemMonitor
        onDashboardClicked: dashboard.toggle()
        onSettingsClicked: settings.toggle()
    }
}
//Quickshell Types: "https://quickshell.org/docs/v0.2.1/types"
//QtQuick Types: "https://doc.qt.io/qt-6/qtquick-qmlmodule.html"
//quickshell shell example1: "https://github.com/caelestia-dots/shell"
//quickshell shell example2: "https://github.com/end-4/dots-hyprland/tree/main/dots/.config/quickshell/ii"
