import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    required property string label
    required property string iconName
    property real value: 0
    property real to: 1
    property bool enabledState: true
    property real dragValue: value
    readonly property bool dragging: sliderMouseArea.pressed
    readonly property real displayValue: dragging ? dragValue : value
    readonly property real normalizedValue: to > 0 ? Math.max(0, Math.min(1, displayValue / to)) : 0
    signal moved(real value)

    Layout.fillWidth: true
    spacing: 6
    opacity: enabledState ? 1 : 0.48

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ThemedSvgIcon {
            iconName: root.iconName
            iconSize: 16
            color: Theme.icon
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.text
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Text {
            text: `${Math.round(root.displayValue * 100)}%`
            color: Theme.subtext
            font.pixelSize: 12
        }
    }

    Item {
        id: slider

        Layout.fillWidth: true
        implicitHeight: 20

        function moveAt(mouseX) {
            const ratio = Math.max(0, Math.min(1, mouseX / width));
            root.dragValue = ratio * root.to;
            root.moved(root.dragValue);
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Qt.alpha(Theme.surface2, root.enabledState ? 0.72 : 0.35)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, slider.width * root.normalizedValue)
            height: 4
            radius: 2
            color: root.enabledState ? Theme.accent : Qt.alpha(Theme.subtext, 0.32)
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            y: 3
            x: Math.max(0, Math.min(parent.width - width, parent.width * root.normalizedValue - width / 2))
            color: root.enabledState ? Theme.text : Qt.alpha(Theme.subtext, 0.45)
            border.width: 1
            border.color: root.enabledState ? Qt.alpha(Theme.accent, 0.65) : Qt.alpha(Theme.text, 0.08)
        }

        MouseArea {
            id: sliderMouseArea

            anchors.fill: parent
            enabled: root.enabledState
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => slider.moveAt(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    slider.moveAt(mouse.x);
            }
        }
    }
}
