import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    width: 35
    height: 35
    property string side: "right"
    signal clicked

    readonly property bool hovered: mouseArea.containsMouse
    readonly property string panelIcon: side === "top" ? "panel-top-open" : (side === "left" ? "panel-left-open" : "panel-right-open")

    ThemedSvgIcon {
        anchors.centerIn: parent
        iconName: root.panelIcon
        iconSize: 24
        color: Theme.accent
        opacity: root.hovered ? 0.14 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }

    ThemedSvgIcon {
        anchors.centerIn: parent
        iconName: root.panelIcon
        iconSize: 24
        color: root.hovered ? Theme.barIconActive : Theme.barIcon
        opacity: root.hovered ? 1.0 : 0.94
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
