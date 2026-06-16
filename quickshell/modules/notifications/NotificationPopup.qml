pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQml
import Quickshell
import Quickshell.Services.Notifications
import "../../components"
import "../../services"

Item {
    id: root

    required property QtObject entry

    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property bool hasImage: entry.image && entry.image.length > 0
    readonly property bool hasActions: entry.actions && entry.actions.length > 0

    width: 360
    implicitHeight: Math.max(92, card.implicitHeight)
    opacity: entry.popupEntered && !entry.popupClosing ? 1 : 0

    transform: Translate {
        x: root.entry.popupClosing ? -root.width - 16 : 0
        y: root.entry.popupEntered ? 0 : -root.height - 12

        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.InCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
    }

    Component.onCompleted: {
        if (!entry.popupEntered)
            Qt.callLater(() => entry.popupEntered = true);
    }

    Behavior on y {
        enabled: entry.popupEntered && !entry.popupClosing

        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        blur: 18
        spread: 0
        offset: Qt.vector2d(0, 6)
        color: "#42000000"
        cached: true
    }

    Rectangle {
        id: card

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: content.implicitHeight + 24
        radius: 4
        color: Qt.alpha(Theme.mantle, 0.96)
        border.width: 1
        border.color: root.critical ? Qt.alpha(Theme.accent2, 0.58) : Qt.alpha(Theme.accent, 0.42)
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 3
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.05)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: root.critical ? Theme.accent2 : Theme.accent
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: root.hasActions ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    root.entry.close();
                    return;
                }

                if (root.entry.actions.length === 1) {
                    root.entry.actions[0].invoke();
                    root.entry.close();
                }
            }
        }

        RowLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                Layout.alignment: Qt.AlignTop
                radius: 4
                color: Qt.alpha(root.critical ? Theme.accent2 : Theme.accent, 0.16)
                border.width: 1
                border.color: Qt.alpha(root.critical ? Theme.accent2 : Theme.accent, 0.28)
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 0
                    source: root.hasImage ? Qt.resolvedUrl(root.entry.image) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: root.hasImage
                }

                Text {
                    anchors.centerIn: parent
                    text: root.critical ? Icons.triangleAlert : Icons.bell
                    color: root.critical ? Theme.accent2 : Theme.accent
                    font.family: Icons.family
                    font.pixelSize: 21
                    visible: !root.hasImage
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.entry.appName || SettingsService.t("Notifications")
                        color: Theme.accent
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Text {
                        text: Qt.formatDateTime(root.entry.time, "hh:mm")
                        color: Theme.subtext
                        font.pixelSize: 11
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.entry.summary || SettingsService.t("Notifications")
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.entry.body || ""
                    color: Theme.subtext
                    font.pixelSize: 12
                    lineHeight: 1.08
                    textFormat: Text.PlainText
                    maximumLineCount: 3
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    visible: text.length > 0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.hasActions

                    Repeater {
                        model: root.entry.actions.slice(0, 2)

                        Rectangle {
                            required property var modelData

                            Layout.preferredHeight: 24
                            Layout.fillWidth: true
                            radius: 4
                            color: Qt.alpha(Theme.accent, actionMouse.containsMouse ? 0.20 : 0.12)
                            border.width: 1
                            border.color: Qt.alpha(Theme.accent, 0.30)

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 14
                                text: modelData.text || "Action"
                                color: Theme.text
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: actionMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    modelData.invoke();
                                    root.entry.close();
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignTop
                radius: 4
                color: closeMouse.containsMouse ? Qt.alpha(Theme.text, 0.10) : "transparent"

                ThemedSvgIcon {
                    anchors.centerIn: parent
                    iconName: "x"
                    color: Theme.subtext
                    iconSize: 14
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.entry.dismissPopup()
                }
            }
        }
    }
}
