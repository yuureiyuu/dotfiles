pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../systemMonitor"

PanelWindow {
    id: root

    required property var dashboard
    property int activePage: 0
    property int incomingPage: 0
    property int pageDirection: 1
    readonly property int navPage: pageSwitch.running ? incomingPage : activePage
    property string osName: "Linux"
    readonly property string wmName: {
        if ((Quickshell.env("NIRI_SOCKET") || "").length)
            return "niri";
        if ((Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "").length)
            return "Hyprland";
        return Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("DESKTOP_SESSION") || "Unknown";
    }

    function pageComponent(index) {
        if (index === 0)
            return homePageComponent;
        if (index === 1)
            return planPageComponent;
        return workspacesPageComponent;
    }

    function setPage(index) {
        if (index === root.activePage && !pageSwitch.running)
            return;

        if (pageSwitch.running) {
            pageSwitch.stop();
            root.activePage = root.incomingPage;
            currentPageLoader.sourceComponent = root.pageComponent(root.activePage);
            currentPageLoader.x = 0;
            currentPageLoader.opacity = 1;
            incomingPageLoader.active = false;
            incomingPageLoader.visible = false;
        }

        root.pageDirection = index > root.activePage ? 1 : -1;
        root.incomingPage = index;
        incomingPageLoader.sourceComponent = root.pageComponent(index);
        incomingPageLoader.active = true;
        incomingPageLoader.visible = true;
        incomingPageLoader.x = root.pageDirection * 38;
        incomingPageLoader.opacity = 0;
        currentPageLoader.x = 0;
        currentPageLoader.opacity = 1;
        pageSwitch.restart();
    }

    function requestClose() {
        root.dashboard.close();
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    SystemStatsConsumer {
        active: SettingsService.systemStatsService
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const match = text().match(/^PRETTY_NAME="?([^"\n]+)"?/m);
            root.osName = match ? match[1] : "Linux";
        }
    }

    HyprlandFocusGrab {
        active: false
        windows: [root]
        onCleared: root.requestClose()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: root.dashboard.revealed && !root.dashboard.closing
            onClicked: root.requestClose()
        }

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 26
            spread: 0
            offset: Qt.vector2d(0, 8)
            color: "#42000000"
            cached: true
        }

        Rectangle {
            id: card

            width: Math.min(parent.width - 36, SettingsService.scaled(root.navPage === 2 ? 1160 : 1020))
            height: Math.min(parent.height - 28, SettingsService.scaled(root.navPage === 2 ? 350 : 560))
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.dashboard.revealed ? 10 : -height - 28
            opacity: root.dashboard.revealed ? 1 : 0
            radius: 6
            clip: true
            color: Theme.base
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.30)

            Behavior on width {
                NumberAnimation {
                    duration: SettingsService.duration(190)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: SettingsService.duration(190)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: SettingsService.duration(230)
                    easing.type: Easing.OutCubic
                    onRunningChanged: {
                        if (!running && root.dashboard.closing && !root.dashboard.revealed)
                            root.dashboard.finishClose();
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: SettingsService.duration(150)
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: mouse => mouse.accepted = true
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 88
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.accent, 0.18)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.accent, 0)
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.fillHeight: true
                    radius: 5
                    color: Qt.alpha(Theme.mantle, 0.88)
                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.08)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Repeater {
                            model: [
                                {
                                    "icon": "home",
                                    "label": SettingsService.t("Home")
                                },
                                {
                                    "icon": "calendar-days",
                                    "label": SettingsService.t("Plan")
                                },
                                {
                                    "icon": "layout-dashboard",
                                    "label": SettingsService.t("Spaces")
                                }
                            ]

                            delegate: DashboardPageButton {
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                iconName: modelData.icon
                                label: modelData.label
                                active: root.navPage === index
                                onClicked: root.setPage(index)
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }

                Item {
                    id: pageStack

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: currentPageLoader
                        anchors.fill: parent
                        asynchronous: true
                        sourceComponent: root.pageComponent(root.activePage)
                    }

                    Loader {
                        id: incomingPageLoader
                        anchors.fill: parent
                        asynchronous: true
                        active: false
                        visible: false
                    }

                    ParallelAnimation {
                        id: pageSwitch

                        NumberAnimation {
                            target: currentPageLoader
                            property: "x"
                            to: -root.pageDirection * 38
                            duration: SettingsService.duration(180)
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: currentPageLoader
                            property: "opacity"
                            to: 0
                            duration: SettingsService.duration(130)
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: incomingPageLoader
                            property: "x"
                            to: 0
                            duration: SettingsService.duration(210)
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: incomingPageLoader
                            property: "opacity"
                            to: 1
                            duration: SettingsService.duration(160)
                            easing.type: Easing.OutCubic
                        }

                        onStopped: {
                            root.activePage = root.incomingPage;
                            currentPageLoader.sourceComponent = root.pageComponent(root.activePage);
                            currentPageLoader.x = 0;
                            currentPageLoader.opacity = 1;
                            incomingPageLoader.active = false;
                            incomingPageLoader.visible = false;
                            incomingPageLoader.sourceComponent = null;
                        }
                    }

                    Component {
                        id: homePageComponent

                        HomePage {
                            osName: root.osName
                            wmName: root.wmName
                        }
                    }

                    Component {
                        id: planPageComponent

                        PlanPage {}
                    }

                    Component {
                        id: workspacesPageComponent

                        WorkspacesPage {}
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.requestClose();
                    event.accepted = true;
                } else if (event.key === Qt.Key_1) {
                    root.setPage(0);
                    event.accepted = true;
                } else if (event.key === Qt.Key_2) {
                    root.setPage(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_3) {
                    root.setPage(2);
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
        }
    }
}
