import QtQuick
import QtQuick.Layouts
import "../../services"

RowLayout {
    id: root

    required property string label
    property bool checked: false
    property bool enabledState: true
    signal toggled(bool checked)

    Layout.fillWidth: true
    spacing: 10
    opacity: enabledState ? 1 : 0.48

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Theme.text
        font.pixelSize: 13
        elide: Text.ElideRight
    }

    Rectangle {
        Layout.preferredWidth: 38
        Layout.preferredHeight: 20
        radius: 10
        color: root.checked ? Qt.alpha(Theme.accent, 0.88) : Qt.alpha(Theme.surface2, 0.70)
        border.width: 1
        border.color: root.checked ? Qt.alpha(Theme.accent, 1) : Qt.alpha(Theme.text, 0.12)

        Rectangle {
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.base : Theme.subtext

            Behavior on x {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.enabledState
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
