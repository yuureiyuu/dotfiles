pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../services"
import "../../components"

Flickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        width: root.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: `${Notifications.list.length} notifications`
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            PanelButton {
                text: "Clear"
                iconName: "trash-2"
                enabledState: Notifications.list.length > 0
                onClicked: Notifications.clear()
            }
        }

        Repeater {
            model: Notifications.list

            Rectangle {
                id: notificationItem

                required property var modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                Layout.fillWidth: true
                implicitHeight: Math.max(76, content.implicitHeight + 22)
                radius: 6
                color: Qt.alpha(critical ? Theme.accent2 : Theme.mantle, critical ? 0.20 : 0.74)
                border.width: 1
                border.color: Qt.alpha(critical ? Theme.accent2 : Theme.text, critical ? 0.46 : 0.08)

                ColumnLayout {
                    id: content

                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: notificationItem.modelData.appName || "Notification"
                            color: Theme.subtext
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            text: Qt.formatTime(notificationItem.modelData.time, "HH:mm")
                            color: Theme.subtext
                            font.pixelSize: 11
                        }

                        IconButton {
                            iconName: "x"
                            size: 24
                            onClicked: notificationItem.modelData.close()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: notificationItem.modelData.summary || "Notification"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: notificationItem.modelData.body.length > 0
                        text: notificationItem.modelData.body
                        color: Theme.subtext
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Notifications.list.length === 0
            text: "Notification history is empty."
            color: Theme.subtext
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            topPadding: 28
        }
    }
}
