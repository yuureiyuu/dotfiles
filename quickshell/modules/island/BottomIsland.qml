import QtQuick
import QtQuick.Effects
import Quickshell
import "../../services"

PanelWindow {
    id: root

    required property var appLauncher
    required property var systemMonitor
    required property var dashboard
    required property var settings

    signal dashboardClicked
    signal settingsClicked

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    visible: SettingsService.islandEnabled
    mask: Region {
        item: inputRegion
    }

    anchors {
        left: true
        right: true
        bottom: true
    }

    implicitHeight: SettingsService.compactIsland ? 62 : 82

    readonly property bool islandHovered: hotZoneMouseArea.containsMouse || appLauncherButton.hovered || dashboardButton.hovered || systemMonitorButton.hovered || settingsButton.hovered

    Item {
        id: inputRegion

        width: SettingsService.compactIsland ? 198 : 250
        height: root.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        RectangularShadow {
            anchors.fill: islandSurface
            radius: islandSurface.radius
            blur: 16
            spread: 0
            offset: Qt.vector2d(0, 2)
            color: "#30000000"
            cached: true
        }

        Rectangle {
            id: islandSurface

            width: SettingsService.compactIsland ? 198 : 250
            height: SettingsService.compactIsland ? 44 : 54
            radius: 4
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.islandHovered ? 12 : (SettingsService.compactIsland ? -31 : -39)
            color: Qt.alpha(Theme.mantle, 0.94)
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.30)

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: SettingsService.duration(220)
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                anchors.fill: parent
                anchors.margins: 4

                IslandButton {
                    id: appLauncherButton

                    iconName: "stiker"
                    active: root.appLauncher.open
                    onClicked: root.appLauncher.toggle()
                }

                IslandSeparator {}

                IslandButton {
                    id: dashboardButton

                    iconName: "warehouse"
                    active: root.dashboard.open
                    onClicked: root.dashboardClicked()
                }

                IslandSeparator {}

                IslandButton {
                    id: systemMonitorButton

                    iconName: "activity"
                    active: root.systemMonitor.open
                    onClicked: root.systemMonitor.toggle()
                }

                IslandSeparator {}

                IslandButton {
                    id: settingsButton

                    iconName: "settings"
                    active: root.settings.open
                    onClicked: root.settingsClicked()
                }
            }
        }

        Item {
            width: islandSurface.width
            height: 14
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            MouseArea {
                id: hotZoneMouseArea

                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    component IslandSeparator: Rectangle {
        width: 1
        height: SettingsService.compactIsland ? 22 : 28
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.alpha(Theme.text, 0.12)
    }
}
