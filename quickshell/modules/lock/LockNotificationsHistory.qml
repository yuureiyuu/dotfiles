pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../components"
import "../../services"

Rectangle {
    id: root

    property real uiScale: 1
    property Item blurSource: null

    radius: 4
    color: Qt.alpha(Theme.base, 0.76)
    border.width: 1
    border.color: Qt.alpha(Theme.text, 0.14)
    clip: true

    Item {
        anchors.fill: parent
        clip: true

        ShaderEffectSource {
            id: notificationsBlurSource

            anchors.fill: parent
            sourceItem: root.blurSource
            sourceRect: Qt.rect(root.x, root.y, root.width, root.height)
            visible: false
            live: true
            recursive: false
        }

        MultiEffect {
            anchors.fill: parent
            source: notificationsBlurSource
            visible: root.blurSource !== null
            maskEnabled: true
            maskSource: notificationsMask
            blurEnabled: true
            blur: 0.55
            blurMax: 26
            saturation: 0.96
            brightness: -0.06
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.color
        }
    }

    Item {
        id: notificationsMask

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "white"
        }
    }

    ColumnLayout {
        z: 2
        anchors.fill: parent
        anchors.margins: 14 * root.uiScale
        spacing: 10 * root.uiScale

        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            ThemedSvgIcon {
                Layout.preferredWidth: 19 * root.uiScale
                Layout.preferredHeight: 19 * root.uiScale
                iconName: Notifications.unreadCount > 0 ? "bell-dot" : "bell"
                iconSize: 19 * root.uiScale
                color: Theme.accent
            }

            Text {
                Layout.fillWidth: true
                text: `${Notifications.list.length} notifications`
                color: Theme.text
                font.pixelSize: 15 * root.uiScale
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                id: clearButton

                Layout.preferredWidth: 74 * root.uiScale
                Layout.preferredHeight: 30 * root.uiScale
                radius: 4
                color: clearMouseArea.containsMouse && Notifications.list.length > 0 ? Qt.alpha(Theme.text, 0.09) : Qt.alpha(Theme.text, 0.04)
                border.width: 1
                border.color: Notifications.list.length > 0 ? Qt.alpha(Theme.text, 0.10) : Qt.alpha(Theme.text, 0.05)
                opacity: Notifications.list.length > 0 ? 1 : 0.45

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5 * root.uiScale

                    ThemedSvgIcon {
                        Layout.preferredWidth: 13 * root.uiScale
                        Layout.preferredHeight: 13 * root.uiScale
                        iconName: "trash-2"
                        iconSize: 13 * root.uiScale
                        color: Theme.icon
                    }

                    Text {
                        text: SettingsService.t("Clear")
                        color: Theme.text
                        font.pixelSize: 11 * root.uiScale
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: clearMouseArea

                    anchors.fill: parent
                    enabled: Notifications.list.length > 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clear()
                }
            }
        }

        Flickable {
            id: notificationFlick

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: notificationList.implicitHeight

            ColumnLayout {
                id: notificationList

                width: notificationFlick.width
                spacing: 9 * root.uiScale

                Repeater {
                    model: Notifications.list

                    Rectangle {
                        id: notificationItem

                        required property var modelData
                        readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                        Layout.fillWidth: true
                        implicitHeight: Math.max(78 * root.uiScale, notificationContent.implicitHeight + 22 * root.uiScale)
                        radius: 4
                        color: Qt.alpha(critical ? Theme.accent2 : Theme.mantle, critical ? 0.20 : 0.74)
                        border.width: 1
                        border.color: Qt.alpha(critical ? Theme.accent2 : Theme.text, critical ? 0.46 : 0.08)

                        ColumnLayout {
                            id: notificationContent

                            anchors.fill: parent
                            anchors.margins: 11 * root.uiScale
                            spacing: 4 * root.uiScale

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8 * root.uiScale

                                Text {
                                    Layout.fillWidth: true
                                    text: notificationItem.modelData.appName || SettingsService.t("Notifications")
                                    color: Theme.subtext
                                    font.pixelSize: 11 * root.uiScale
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: Qt.formatTime(notificationItem.modelData.time, "HH:mm")
                                    color: Theme.subtext
                                    font.pixelSize: 11 * root.uiScale
                                }

                                Rectangle {
                                    Layout.preferredWidth: 24 * root.uiScale
                                    Layout.preferredHeight: 24 * root.uiScale
                                    radius: 4
                                    color: closeMouseArea.containsMouse ? Qt.alpha(Theme.text, 0.08) : "transparent"

                                    ThemedSvgIcon {
                                        anchors.centerIn: parent
                                        iconName: "x"
                                        iconSize: 15 * root.uiScale
                                        color: Theme.icon
                                    }

                                    MouseArea {
                                        id: closeMouseArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notificationItem.modelData.close()
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: notificationItem.modelData.summary || SettingsService.t("Notifications")
                                color: Theme.text
                                font.pixelSize: 13 * root.uiScale
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: notificationItem.modelData.body.length > 0
                                text: notificationItem.modelData.body.replace(/<[^>]*>/g, "")
                                color: Theme.subtext
                                font.pixelSize: 12 * root.uiScale
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Text {
                    width: notificationFlick.width
                    visible: Notifications.list.length === 0
                    text: SettingsService.t("Notification history is empty.")
                    color: Theme.subtext
                    font.pixelSize: 12 * root.uiScale
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 28 * root.uiScale
                }
            }
        }
    }

    Rectangle {
        z: 3
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.14)
    }
}
