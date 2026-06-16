pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

ColumnLayout {
    id: root

    property real uiScale: 1

    spacing: 14 * root.uiScale

    Rectangle {
        visible: SettingsService.systemStatsService
        Layout.fillWidth: true
        Layout.preferredHeight: 138 * root.uiScale
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
            spacing: 8 * root.uiScale

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "System"
                color: Theme.text
                font.pixelSize: 28 * root.uiScale
                font.weight: Font.DemiBold
            }

            GridLayout {
                columns: 2
                rowSpacing: 4 * root.uiScale
                columnSpacing: 10 * root.uiScale

                Text {
                    text: "Host"
                    color: Theme.subtext
                    font.pixelSize: 12 * root.uiScale
                }
                Text {
                    text: SystemStats.hostname
                    color: "white"
                    font.pixelSize: 12 * root.uiScale
                    elide: Text.ElideRight
                }

                Text {
                    text: "User"
                    color: Theme.subtext
                    font.pixelSize: 12 * root.uiScale
                }
                Text {
                    text: SystemStats.username
                    color: "white"
                    font.pixelSize: 12 * root.uiScale
                    elide: Text.ElideRight
                }

                Text {
                    text: "Session"
                    color: Theme.subtext
                    font.pixelSize: 12 * root.uiScale
                }
                Text {
                    text: "Hyprland"
                    color: "white"
                    font.pixelSize: 12 * root.uiScale
                }

                Text {
                    text: "Uptime"
                    color: Theme.subtext
                    font.pixelSize: 12 * root.uiScale
                }
                Text {
                    text: SystemStats.uptimeText
                    color: "white"
                    font.pixelSize: 12 * root.uiScale
                }
            }
        }
    }

    Rectangle {
        visible: SettingsService.nowPlayingService
        Layout.fillWidth: true
        Layout.fillHeight: visible
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
            spacing: 8 * root.uiScale

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Now playing"
                color: Theme.accent
                font.pixelSize: 14 * root.uiScale
                font.weight: Font.DemiBold
            }

            Text {
                text: NowPlaying.title.length ? NowPlaying.title : "Nothing is playing"
                color: Theme.text
                font.pixelSize: 22 * root.uiScale
                font.weight: Font.DemiBold
                maximumLineCount: 2
                wrapMode: Text.Wrap
                elide: Text.ElideRight
            }

            Text {
                visible: NowPlaying.artist.length > 0
                text: NowPlaying.artist
                color: Qt.rgba(1, 1, 1, 0.78)
                font.pixelSize: 15 * root.uiScale
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            Text {
                visible: NowPlaying.player.length > 0
                text: NowPlaying.player
                color: Theme.subtext
                font.pixelSize: 12 * root.uiScale
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
