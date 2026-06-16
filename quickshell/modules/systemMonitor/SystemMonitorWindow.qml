pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    required property var monitor
    property int activeTab: 0

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:system-monitor"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function formatRate(bytes) {
        return `${SystemStats.formatBytes(bytes)}/s`;
    }

    function metricValue(name) {
        if (name === "CPU")
            return SystemStats.cpuUsage;
        if (name === "RAM")
            return SystemStats.memoryUsage;
        if (name === "GPU")
            return SystemStats.gpuUsage;
        return Math.min(100, SystemStats.networkRxRate / 1048576 * 12);
    }

    function focusProcessList() {
        if (processesPane)
            processesPane.focusList();
    }

    function focusProcessSearch() {
        if (processesPane)
            processesPane.focusSearch();
    }

    onActiveTabChanged: {
        if (activeTab === 1)
            focusProcessList();
    }

    SystemStatsConsumer {}

    HyprlandFocusGrab {
        active: false
        windows: [root]
        onCleared: monitor.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.monitor.revealed ? 0.36 : 0)

        Behavior on color {
            ColorAnimation {
                duration: 180
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: monitor.close()
        }

        Rectangle {
            id: card

            width: Math.min(parent.width - 48, 1240)
            height: Math.min(parent.height - 48, 780)
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.monitor.revealed ? 0 : 22
            opacity: root.monitor.revealed ? 1 : 0
            radius: 4
            color: Theme.base
            border.width: 1
            border.color: Theme.border
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: mouse => mouse.accepted = true
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            Behavior on anchors.verticalCenterOffset {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: card.radius
                color: Theme.base
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 250
                    Layout.fillHeight: true
                    radius: 4
                    color: Qt.alpha(Theme.surface, 0.44)
                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.08)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: "System Monitor"
                                color: Theme.text
                                font.pixelSize: 25
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: `${SystemStats.hostname} / ${SystemStats.username}`
                                color: Theme.subtext
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                radius: 4
                                color: root.activeTab === 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"
                                border.width: root.activeTab === 0 ? 1 : 0
                                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    text: "Statistics"
                                    color: root.activeTab === 0 ? Theme.text : Theme.subtext
                                    font.pixelSize: 14
                                    font.weight: root.activeTab === 0 ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.activeTab = 0
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                radius: 4
                                color: root.activeTab === 1 ? Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.18) : "transparent"
                                border.width: root.activeTab === 1 ? 1 : 0
                                border.color: Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.5)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Processes"
                                        color: root.activeTab === 1 ? Theme.text : Theme.subtext
                                        font.pixelSize: 14
                                        font.weight: root.activeTab === 1 ? Font.DemiBold : Font.Normal
                                    }

                                    Text {
                                        text: String(processesPane.filteredCount)
                                        color: Theme.subtext
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.activeTab = 1;
                                        root.focusProcessList();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.border
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: [["CPU", `${Math.round(SystemStats.cpuUsage)}%`, Theme.accent], ["RAM", `${Math.round(SystemStats.memoryUsage)}%`, Theme.accent2], ["GPU", SystemStats.gpuDisplayText, Theme.swatch2], ["NET", `${root.formatRate(SystemStats.networkRxRate)} down`, Theme.swatch0]]

                                Rectangle {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 66
                                    radius: 4
                                    color: Qt.alpha(Theme.surface, 0.26)
                                    border.width: 0
                                    border.color: "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 10

                                        CircularMeter {
                                            Layout.preferredWidth: 48
                                            Layout.preferredHeight: 48
                                            value: root.metricValue(modelData[0])
                                            accent: modelData[2]
                                            text: ""
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: modelData[0]
                                                color: Theme.subtext
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData[1]
                                                color: modelData[2]
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 12
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    SystemMonitorOverview {
                        anchors.fill: parent
                        visible: root.activeTab === 0
                    }

                    SystemMonitorProcesses {
                        id: processesPane

                        anchors.fill: parent
                        active: root.activeTab === 1
                        visible: root.activeTab === 1
                        onRequestStatistics: {
                            root.activeTab = 0;
                            card.forceActiveFocus();
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    monitor.close();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                    root.activeTab = root.activeTab === 0 ? 1 : 0;
                    event.accepted = true;
                    if (root.activeTab === 1)
                        root.focusProcessList();
                } else if (event.key === Qt.Key_Right) {
                    root.activeTab = 1;
                    root.focusProcessList();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    root.activeTab = 0;
                    event.accepted = true;
                } else if (root.activeTab === 1 && event.key === Qt.Key_Slash) {
                    root.focusProcessSearch();
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
        }
    }
}
