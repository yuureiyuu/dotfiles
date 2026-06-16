import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

Rectangle {
    id: root

    required property string iconName
    required property string title
    property string subtitle: ""
    property bool active: false
    property string actionIcon: active ? "unlink" : "link"
    property bool actionVisible: true
    property bool enabledState: true
    readonly property bool hovered: mouseArea.containsMouse
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 44
    radius: 5
    color: active ? Qt.alpha(Theme.accent, 0.16) : Qt.alpha(Theme.surface, 0.38)
    border.width: 1
    border.color: active ? Qt.alpha(Theme.accent, 0.36) : Qt.alpha(Theme.text, 0.08)
    opacity: enabledState ? 1 : 0.52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 9

        ThemedSvgIcon {
            iconName: root.iconName
            iconSize: 17
            color: root.active ? Theme.accent : Theme.icon
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.text
                font.pixelSize: 13
                font.weight: root.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: Theme.subtext
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        ThemedSvgIcon {
            visible: root.actionVisible
            iconName: root.actionIcon
            iconSize: 16
            color: root.hovered && root.enabledState ? Theme.accent : Theme.icon
            opacity: root.hovered && root.enabledState ? 1 : 0.72
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.enabledState
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
