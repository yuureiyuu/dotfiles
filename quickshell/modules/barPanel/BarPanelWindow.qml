pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    required property var panel
    property int activePage: 0
    readonly property int edgeMargin: 4
    readonly property int shadowMargin: 34
    readonly property int panelWidth: SettingsService.scaled(430)
    readonly property int panelHeight: SettingsService.scaled(430)
    readonly property string side: SettingsService.barPosition
    readonly property bool fromLeft: side === "left"
    readonly property bool fromTop: side === "top"
    readonly property bool fromRight: !fromLeft && !fromTop
    property int previousPage: 0
    property int pageDirection: 1

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    implicitWidth: root.fromTop ? 1 : panelWidth + edgeMargin * 2 + shadowMargin
    implicitHeight: root.fromTop ? panelHeight + edgeMargin * 2 + shadowMargin : 1
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function pageComponent(index) {
        if (index === 1)
            return audioPage;
        if (index === 2)
            return notificationsPage;
        return controlsPage;
    }

    onActivePageChanged: {
        pageDirection = activePage >= previousPage ? 1 : -1;
        previousPage = activePage;
        if (pageStack.depth > 0)
            pageStack.replace(pageComponent(activePage));
    }

    anchors {
        top: true
        bottom: !root.fromTop
        left: root.fromLeft || root.fromTop
        right: root.fromRight || root.fromTop
    }

    HyprlandFocusGrab {
        active: false
        windows: [root]
        onCleared: root.panel.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.panel.close()
        }

        RectangularShadow {
            anchors.fill: shadowShape
            radius: panelSurface.radius
            blur: 24
            spread: 0
            offset: root.fromTop ? Qt.vector2d(0, 10) : Qt.vector2d(root.fromLeft ? 10 : -10, 0)
            color: "#34000000"
            opacity: root.panel.revealProgress
            cached: false
        }

        Rectangle {
            id: shadowShape

            width: panelSurface.width
            height: panelSurface.height
            x: panelSurface.x
            y: panelSurface.y
            radius: panelSurface.radius
            color: "transparent"
        }

        Rectangle {
            id: panelSurface

            width: root.fromTop ? Math.min(parent.width - root.edgeMargin * 2, 560) : root.panelWidth
            height: root.fromTop ? root.panelHeight : parent.height - root.edgeMargin * 2
            x: {
                if (root.fromTop)
                    return (parent.width - width) / 2;
                if (root.fromLeft)
                    return -root.panelWidth - root.edgeMargin + (root.panelWidth + root.edgeMargin * 2) * root.panel.revealProgress;
                return parent.width + root.edgeMargin - (root.panelWidth + root.edgeMargin * 2) * root.panel.revealProgress;
            }
            y: root.fromTop ? (-root.panelHeight - root.edgeMargin + (root.panelHeight + root.edgeMargin * 2) * root.panel.revealProgress) : root.edgeMargin
            radius: 6
            clip: true
            opacity: root.panel.revealProgress
            color: Theme.base
            border.width: 1
            border.color: Qt.alpha(Theme.border, 0.62)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: mouse => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            { icon: "sliders-horizontal", label: SettingsService.t("Control") },
                            { icon: "volume-2", label: SettingsService.t("Audio") },
                            { icon: "bell", label: SettingsService.t("History") }
                        ]

                        delegate: TabButton {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            iconName: modelData.icon
                            label: modelData.label
                            active: root.activePage === index
                            onClicked: root.activePage = index
                        }
                    }

                    IconButton {
                        iconName: "x"
                        onClicked: root.panel.close()
                    }
                }

                QQC.StackView {
                    id: pageStack

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    initialItem: controlsPage

                    replaceEnter: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: SettingsService.duration(170)
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                property: "x"
                                from: root.pageDirection > 0 ? 24 : -24
                                to: 0
                                duration: SettingsService.duration(170)
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    replaceExit: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                from: 1
                                to: 0
                                duration: SettingsService.duration(130)
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                property: "x"
                                from: 0
                                to: root.pageDirection > 0 ? -18 : 18
                                duration: SettingsService.duration(130)
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.panel.close();
                    event.accepted = true;
                } else if (event.key === Qt.Key_1) {
                    root.activePage = 0;
                    event.accepted = true;
                } else if (event.key === Qt.Key_2) {
                    root.activePage = 1;
                    event.accepted = true;
                } else if (event.key === Qt.Key_3) {
                    root.activePage = 2;
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
        }
    }

    Component {
        id: controlsPage
        ControlsPage {}
    }

    Component {
        id: audioPage
        AudioPage {}
    }

    Component {
        id: notificationsPage
        NotificationsPage {}
    }
}
