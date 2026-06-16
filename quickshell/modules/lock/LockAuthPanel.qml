pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../components"
import "../../services"

Item {
    id: root

    property real uiScale: 1
    property date currentDate: new Date()
    property string avatarPath: ""
    property int visiblePasswordLength: 0
    property bool passwordActive: false
    property int passwordBufferLength: 0
    property string statusText: ""

    signal submitRequested

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8 * root.uiScale
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 0
                width: Math.min(parent.width, 440 * root.uiScale)
                spacing: 16 * root.uiScale

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3 * root.uiScale

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12 * root.uiScale

                        Text {
                            text: Qt.formatDateTime(root.currentDate, "h:mm")
                            color: Theme.text
                            font.pixelSize: 108 * root.uiScale
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0
                            lineHeight: 0.92
                        }

                        Text {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 14 * root.uiScale
                            text: Qt.formatDateTime(root.currentDate, "AP").toLowerCase()
                            color: Qt.alpha(Theme.text, 0.72)
                            font.pixelSize: 25 * root.uiScale
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0
                        }
                    }

                    Text {
                        text: Qt.formatDateTime(root.currentDate, "dddd, d MMMM")
                        color: Qt.alpha(Theme.text, 0.78)
                        font.pixelSize: 22 * root.uiScale
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4 * root.uiScale
                    width: 166 * root.uiScale
                    height: 166 * root.uiScale
                    radius: width / 2
                    color: Qt.alpha(Theme.base, 0.74)
                    border.width: 0
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(Theme.text, 0.16)
                    }

                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        source: root.avatarPath
                        sourceSize.width: 1024
                        sourceSize.height: 1024
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        mipmap: false
                        visible: status === Image.Ready
                        layer.enabled: true
                        layer.smooth: true
                        layer.textureSize: Qt.size(width * 4, height * 4)
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: avatarMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                        }
                    }

                    Item {
                        id: avatarMask
                        anchors.fill: parent
                        layer.enabled: true
                        visible: false

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "white"
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !avatarImage.visible
                        text: SystemStats.username.length ? SystemStats.username.charAt(0).toUpperCase() : "?"
                        color: Theme.text
                        font.pixelSize: 46 * root.uiScale
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: SystemStats.username || "User"
                    color: Theme.text
                    font.pixelSize: 20 * root.uiScale
                    font.weight: Font.DemiBold
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    radius: 4
                    color: Qt.alpha(Theme.base, 0.80)
                    border.width: 1
                    border.color: root.passwordActive ? Qt.alpha(Theme.accent, 0.86) : Qt.alpha(Theme.text, 0.16)
                    implicitHeight: 58 * root.uiScale
                    clip: true

                    Item {
                        anchors.fill: parent
                        anchors.margins: 8 * root.uiScale

                        readonly property real actionButtonSize: 42 * root.uiScale

                        ThemedSvgIcon {
                            id: lockIcon
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 7 * root.uiScale
                            width: parent.actionButtonSize
                            height: parent.actionButtonSize
                            iconName: root.passwordBufferLength ? "user-key" : "lock-keyhole"
                            iconSize: 21 * root.uiScale
                            color: root.passwordActive ? Theme.accent : Qt.alpha(Theme.text, 0.72)
                        }

                        Text {
                            anchors.left: lockIcon.right
                            anchors.right: submitButton.left
                            anchors.leftMargin: 4 * root.uiScale
                            anchors.rightMargin: 8 * root.uiScale
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.visiblePasswordLength > 0 ? Array(root.visiblePasswordLength + 1).join("•") : "Password"
                            color: Theme.text
                            font.pixelSize: 18 * root.uiScale
                            font.letterSpacing: root.visiblePasswordLength > 0 ? 4 : 0
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: submitButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.actionButtonSize
                            height: parent.actionButtonSize
                            radius: 4
                            color: root.passwordBufferLength ? Theme.accent : Qt.alpha(Theme.text, 0.10)
                            border.width: 1
                            border.color: root.passwordBufferLength ? Qt.alpha(Theme.text, 0.18) : Qt.alpha(Theme.text, 0.08)

                            ThemedSvgIcon {
                                anchors.centerIn: parent
                                iconName: "arrow-right"
                                iconSize: 20 * root.uiScale
                                color: root.passwordBufferLength ? Theme.mantle : Theme.text
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.submitRequested()
                            }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.statusText.length ? root.statusText : "Press Enter to unlock"
                    color: root.statusText.length ? "#ffb4ab" : Qt.alpha(Theme.text, 0.58)
                    font.pixelSize: 13 * root.uiScale
                }
            }
        }
    }
}
