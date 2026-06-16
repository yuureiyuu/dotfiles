import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

Rectangle {
    id: root

    property string text: ""
    property string iconName: ""
    property bool enabledState: true
    property bool prominent: false
    signal clicked

    implicitWidth: Math.max(74, content.implicitWidth + 22)
    implicitHeight: 30
    radius: 5
    color: {
        if (!enabledState)
            return Qt.alpha(Theme.surface, 0.26);
        if (prominent)
            return Qt.alpha(Theme.accent, mouseArea.containsMouse ? 0.30 : 0.22);
        return Qt.alpha(Theme.surface, mouseArea.containsMouse ? 0.62 : 0.42);
    }
    border.width: 1
    border.color: prominent ? Qt.alpha(Theme.accent, 0.44) : Qt.alpha(Theme.text, 0.09)
    opacity: enabledState ? 1 : 0.46

    RowLayout {
        id: content

        anchors.centerIn: parent
        spacing: 6

        ThemedSvgIcon {
            visible: root.iconName.length > 0
            iconName: root.iconName
            iconSize: 14
            color: root.prominent ? Theme.accent : Theme.icon
        }

        Text {
            text: root.text
            color: root.prominent ? Theme.text : Theme.subtext
            font.pixelSize: 12
            font.weight: root.prominent ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.enabledState
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.clicked()
    }
}
