import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    required property string iconName
    required property real value
    property real to: 1
    property color fillColor: Theme.accent
    readonly property real normalizedValue: to > 0 ? Math.max(0, Math.min(1, value / to)) : 0

    spacing: 8

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 34
        implicitHeight: 176

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.fill: track
            radius: 9
            color: Qt.alpha(Theme.surface2, 0.58)
        }

        Rectangle {
            id: track

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 176
            radius: 9
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.10)
        }

        Rectangle {
            anchors.horizontalCenter: track.horizontalCenter
            anchors.bottom: track.bottom
            width: track.width
            height: Math.max(track.radius, track.height * root.normalizedValue)
            radius: track.radius
            color: root.fillColor
        }

        Rectangle {
            anchors.horizontalCenter: track.horizontalCenter
            y: Math.max(0, Math.min(track.height - height, track.y + track.height * (1 - root.normalizedValue) - height / 2))
            width: 26
            height: 8
            radius: 4
            color: Theme.text
            border.width: 1
            border.color: Qt.alpha(Theme.base, 0.44)
        }
    }

    ThemedSvgIcon {
        Layout.alignment: Qt.AlignHCenter
        iconName: root.iconName
        iconSize: 19
        color: Theme.icon
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: `${Math.round(root.normalizedValue * 100)}%`
        color: Theme.subtext
        font.pixelSize: 11
        font.weight: Font.Medium
    }
}
