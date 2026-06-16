pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    property real uiScale: 1

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 4
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
    clip: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.04)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Qt.alpha(Theme.text, 0.08)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(0, 0, 0, 0.18)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * root.uiScale
        spacing: 10 * root.uiScale

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28 * root.uiScale

            Text {
                anchors.centerIn: parent
                text: SettingsService.t("Notifications")
                color: "white"
                font.pixelSize: 22 * root.uiScale
                font.weight: Font.DemiBold
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: `${Notifications.unreadCount}`
                color: Theme.accent
                font.pixelSize: 14 * root.uiScale
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: Math.min(Notifications.list.length, 3)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64 * root.uiScale
                radius: 4
                color: Theme.base
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10 * root.uiScale
                    spacing: 3 * root.uiScale

                    Text {
                        text: Notifications.list[index].appName || SettingsService.t("Notifications")
                        color: Theme.accent
                        font.pixelSize: 12 * root.uiScale
                        font.weight: Font.DemiBold
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Text {
                        text: Notifications.list[index].summary || SettingsService.t("No title")
                        color: "white"
                        font.pixelSize: 13 * root.uiScale
                        font.weight: Font.Medium
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Text {
                        text: Notifications.list[index].body || ""
                        color: Theme.subtext
                        font.pixelSize: 11 * root.uiScale
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: Notifications.list.length > 0
        }

        Text {
            visible: Notifications.list.length === 0
            text: SettingsService.t("No notifications")
            color: Theme.subtext
            font.pixelSize: 14 * root.uiScale
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
