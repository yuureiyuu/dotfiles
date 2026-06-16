pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../services"

Scope {
    id: root

    property bool visible: true
    signal powerClicked
    signal barPanelClicked

    readonly property string position: SettingsService.barPosition

    Variants {
        model: Quickshell.screens

        SideBarWindow {
            required property ShellScreen modelData

            screen: modelData
            visible: root.visible && root.position === "right"
            side: "right"
            onPowerClicked: root.powerClicked()
            onBarPanelClicked: root.barPanelClicked()
        }
    }

    Variants {
        model: Quickshell.screens

        SideBarWindow {
            required property ShellScreen modelData

            screen: modelData
            visible: root.visible && root.position === "left"
            side: "left"
            onPowerClicked: root.powerClicked()
            onBarPanelClicked: root.barPanelClicked()
        }
    }

    Variants {
        model: Quickshell.screens

        TopBarWindow {
            required property ShellScreen modelData

            screen: modelData
            visible: root.visible && root.position === "top"
            onPowerClicked: root.powerClicked()
            onBarPanelClicked: root.barPanelClicked()
        }
    }

    component SideBarWindow: PanelWindow {
        id: sideRoot

        required property string side
        readonly property bool leftSide: side === "left"
        readonly property bool rightSide: side === "right"

        signal powerClicked
        signal barPanelClicked

        anchors {
            top: true
            bottom: true
            right: sideRoot.rightSide
            left: sideRoot.leftSide
        }

        implicitWidth: 69 + trayWidget.menuWidth
        exclusiveZone: 69
        color: "transparent"
        mask: Region {
            regions: [
                Region {
                    item: barSurface
                },
                Region {
                    item: trayWidget.menuInputRegion
                }
            ]
        }

        RectangularShadow {
            anchors.fill: barSurface
            radius: 0
            blur: 14
            spread: 0
            offset: Qt.vector2d(sideRoot.leftSide ? 2 : -2, 0)
            color: "#2f000000"
            cached: true
        }

        Rectangle {
            id: barSurface

            anchors {
                top: parent.top
                bottom: parent.bottom
                right: sideRoot.rightSide ? parent.right : undefined
                left: sideRoot.leftSide ? parent.left : undefined
            }
            width: 69
            color: Qt.alpha(Theme.mantle, 0.94)
            radius: 0
            border.width: 0

            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: sideRoot.rightSide ? parent.left : undefined
                    right: sideRoot.leftSide ? parent.right : undefined
                }
                width: 1
                color: Qt.alpha(Theme.accent, 0.32)
                opacity: trayWidget.menuOpen ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: SettingsService.duration(140)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: sideRoot.rightSide ? parent.left : undefined
                    right: sideRoot.leftSide ? parent.right : undefined
                    leftMargin: sideRoot.rightSide ? 1 : 0
                    rightMargin: sideRoot.leftSide ? 1 : 0
                }
                width: 1
                color: Qt.alpha(Theme.text, 0.08)
                opacity: trayWidget.menuOpen ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: SettingsService.duration(140)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: sideRoot.rightSide ? parent.left : undefined
                    right: sideRoot.leftSide ? parent.right : undefined
                    leftMargin: sideRoot.rightSide ? 2 : 0
                    rightMargin: sideRoot.leftSide ? 2 : 0
                }
                width: 10
                opacity: trayWidget.menuOpen ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: SettingsService.duration(140)
                        easing.type: Easing.OutCubic
                    }
                }

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: sideRoot.rightSide ? 0 : 1
                        color: Qt.alpha(Theme.base, 0.2)
                    }

                    GradientStop {
                        position: sideRoot.rightSide ? 1 : 0
                        color: Qt.alpha(Theme.base, 0)
                    }
                }
            }

            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: sideRoot.rightSide ? parent.right : undefined
                    left: sideRoot.leftSide ? parent.left : undefined
                }
                width: 1
                color: Qt.alpha(Theme.base, 0.48)
            }
        }

        Item {
            id: menuOverlay
            anchors.fill: parent
            z: 100
        }

        ClockWidget {
            anchors.top: parent.top
            anchors.horizontalCenter: barSurface.horizontalCenter
            anchors.topMargin: 7
            horizontal: false
        }

        WorkspaceWidget {
            anchors.centerIn: barSurface
            width: 50
            horizontal: false
        }

        TrayWidget {
            id: trayWidget
            anchors.bottom: batteryWidget.top
            anchors.horizontalCenter: barSurface.horizontalCenter
            anchors.bottomMargin: 15 + (batteryWidget.hovered ? batteryWidget.verticalRevealOffset : 0)
            horizontal: false
            side: sideRoot.side
            menuParent: menuOverlay

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: batteryWidget.animationDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        BatteryWidget {
            id: batteryWidget
            anchors.bottom: barPanelButton.top
            anchors.horizontalCenter: barSurface.horizontalCenter
            anchors.bottomMargin: 15
        }

        BarPanelButton {
            id: barPanelButton
            anchors.bottom: powerWidget.top
            anchors.horizontalCenter: barSurface.horizontalCenter
            anchors.bottomMargin: 15
            side: sideRoot.side
            onClicked: sideRoot.barPanelClicked()
        }

        PowerWidget {
            id: powerWidget
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: barSurface.horizontalCenter
            anchors.bottomMargin: 15
            onClicked: sideRoot.powerClicked()
        }
    }

    component TopBarWindow: PanelWindow {
        id: topRoot

        signal powerClicked
        signal barPanelClicked

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 58 + trayWidget.menuHeight
        exclusiveZone: 58
        color: "transparent"
        mask: Region {
            regions: [
                Region {
                    item: barSurface
                },
                Region {
                    item: trayWidget.menuInputRegion
                }
            ]
        }

        RectangularShadow {
            anchors.fill: barSurface
            radius: 0
            blur: 14
            spread: 0
            offset: Qt.vector2d(0, 2)
            color: "#2f000000"
            cached: true
        }

        Rectangle {
            id: barSurface

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 58
            color: Qt.alpha(Theme.mantle, 0.94)
            radius: 0
            border.width: 0

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1
                color: Qt.alpha(Theme.accent, 0.32)
                opacity: trayWidget.menuOpen ? 0 : 1
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: 1
                }
                height: 1
                color: Qt.alpha(Theme.text, 0.08)
                opacity: trayWidget.menuOpen ? 0 : 1
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: 2
                }
                height: 10
                opacity: trayWidget.menuOpen ? 0 : 1

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.base, 0)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.base, 0.2)
                    }
                }
            }
        }

        Item {
            id: menuOverlay
            anchors.fill: parent
            z: 100
        }

        RowLayout {
            anchors.fill: barSurface
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 14

            ClockWidget {
                Layout.alignment: Qt.AlignVCenter
                horizontal: true
            }

            WorkspaceWidget {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 112
                horizontal: true
            }

            Item {
                Layout.fillWidth: true
            }

            TrayWidget {
                id: trayWidget
                Layout.alignment: Qt.AlignVCenter
                horizontal: true
                side: "top"
                menuParent: menuOverlay
            }

            BatteryWidget {
                Layout.alignment: Qt.AlignVCenter
                horizontal: true
            }

            BarPanelButton {
                Layout.alignment: Qt.AlignVCenter
                side: "top"
                onClicked: topRoot.barPanelClicked()
            }

            PowerWidget {
                Layout.alignment: Qt.AlignVCenter
                onClicked: topRoot.powerClicked()
            }
        }
    }
}
