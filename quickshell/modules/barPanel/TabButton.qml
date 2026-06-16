import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

Item {
    id: root

    required property string iconName
    required property string label
    property bool active: false
    signal clicked

    implicitHeight: 38

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: root.active ? Qt.alpha(Theme.accent, 0.18) : (mouseArea.containsMouse ? Qt.alpha(Theme.text, 0.07) : Qt.alpha(Theme.surface, 0.42))
        border.width: 1
        border.color: root.active ? Qt.alpha(Theme.accent, 0.38) : Qt.alpha(Theme.text, 0.08)
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        ThemedSvgIcon {
            iconName: root.iconName
            iconSize: 16
            color: root.active ? Theme.accent : Theme.icon
        }

        Text {
            text: root.label
            color: root.active ? Theme.text : Theme.subtext
            font.pixelSize: 12
            font.weight: root.active ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
