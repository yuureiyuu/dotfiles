pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: root

    function formatRate(bytes) {
        return `${SystemStats.formatBytes(bytes)}/s`;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 248
            columns: 3
            columnSpacing: 14
            rowSpacing: 14

            StatCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "CPU"
                valueText: `${Math.round(SystemStats.cpuUsage)}%`
                detailText: `Uptime ${SystemStats.uptimeText} / ${SystemStats.temperatureText}`
                accent: Theme.accent
                history: SystemStats.cpuUsageHistory
            }

            StatCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Memory"
                valueText: `${Math.round(SystemStats.memoryUsage)}%`
                detailText: SystemStats.memoryDisplayText
                accent: Theme.accent2
                history: SystemStats.memoryUsageHistory
            }

            StatCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "GPU"
                valueText: SystemStats.gpuDisplayText
                detailText: SystemStats.gpuUsageAvailable ? SystemStats.gpuName : SystemStats.gpuStatus
                accent: Theme.swatch2
                history: SystemStats.gpuUsageHistory
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 128
            columns: 4
            columnSpacing: 14
            rowSpacing: 14

            Repeater {
                model: [["Disk", `${Math.round(SystemStats.diskUsage)}%`, SystemStats.diskText, Theme.swatch0, SystemStats.diskUsage], ["Swap", SystemStats.swapDisplayText, `${SystemStats.swapTotalGiB.toFixed(1)} GiB`, Theme.swatch1, SystemStats.swapUsage], ["Battery", SystemStats.batteryDisplayText, SystemStats.batteryCharging ? "Charging" : "Discharging", Theme.swatch2, SystemStats.batteryAvailable ? SystemStats.batteryLevel * 100 : 0], ["Processes", String(SystemStats.processCount), "running now", Theme.accent, Math.min(100, SystemStats.processCount / 4)]]

                Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 4
                    color: Qt.alpha(Theme.surface, 0.72)
                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.08)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text {
                            text: modelData[0]
                            color: Theme.subtext
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData[1]
                            color: modelData[3]
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData[2]
                            color: Theme.subtext
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            radius: 4
                            color: Qt.alpha(Theme.text, 0.06)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(100, modelData[4])) / 100
                                height: parent.height
                                radius: 4
                                color: modelData[3]
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 4
                color: Qt.alpha(Theme.surface, 0.72)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Network"
                            color: Theme.text
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: SystemStats.networkInterface
                            color: Theme.subtext
                            font.pixelSize: 12
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: `Down ${root.formatRate(SystemStats.networkRxRate)}`
                            color: Theme.swatch0
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: `Up ${root.formatRate(SystemStats.networkTxRate)}`
                            color: Theme.swatch1
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    HistoryGraph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        values: SystemStats.networkRxHistory
                        lineColor: Theme.swatch0
                        fillColor: Qt.rgba(Theme.swatch0.r, Theme.swatch0.g, Theme.swatch0.b, 0.16)
                    }

                    HistoryGraph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        values: SystemStats.networkTxHistory
                        lineColor: Theme.swatch1
                        fillColor: Qt.rgba(Theme.swatch1.r, Theme.swatch1.g, Theme.swatch1.b, 0.14)
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 360
                Layout.fillHeight: true
                radius: 4
                color: Qt.alpha(Theme.surface, 0.72)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Top CPU"
                            color: Theme.text
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "ps"
                            color: Theme.subtext
                            font.pixelSize: 12
                        }
                    }

                    Repeater {
                        model: SystemStats.topProcesses

                        Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 4
                            color: Qt.alpha(Theme.text, 0.045)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Text {
                                    Layout.preferredWidth: 46
                                    text: modelData.pid
                                    color: Theme.subtext
                                    font.pixelSize: 11
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Theme.text
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.preferredWidth: 54
                                    text: `${modelData.cpu.toFixed(1)}%`
                                    color: Theme.accent
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
