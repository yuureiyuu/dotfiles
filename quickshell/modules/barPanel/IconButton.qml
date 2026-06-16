import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    required property string iconName
    property bool active: false
    property int size: 34
    signal clicked

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: root.active ? Qt.alpha(Theme.accent, 0.22) : (mouseArea.containsMouse ? Qt.alpha(Theme.text, 0.08) : "transparent")
        border.width: root.active ? 1 : 0
        border.color: Qt.alpha(Theme.accent, 0.38)
    }

    ThemedSvgIcon {
        anchors.centerIn: parent
        iconName: root.iconName
        iconSize: 18
        color: root.active ? Theme.accent : Theme.icon
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
