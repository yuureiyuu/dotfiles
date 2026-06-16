import QtQuick
import "../services"

Item {
    id: root

    property string icon: ""
    property real iconSize: 24
    property color color: Theme.icon

    implicitWidth: iconSize
    implicitHeight: iconSize

    Text {
        anchors.fill: parent
        text: root.icon
        color: root.color
        font.family: Icons.family
        font.pixelSize: root.iconSize
        font.weight: Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        lineHeight: 1
        renderType: Text.QtRendering
        antialiasing: true
    }
}
