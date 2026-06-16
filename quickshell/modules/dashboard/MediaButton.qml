import QtQuick
import QtQuick.Effects
import "../../components"
import "../../services"

Rectangle {
    id: root

    required property string iconName
    property bool primary: false
    readonly property bool hovered: mouseArea.containsMouse
    signal clicked

    implicitWidth: primary ? 48 : 42
    implicitHeight: primary ? 48 : 42
    radius: 6
    scale: hovered && enabled ? 1.07 : 1
    color: enabled ? (primary ? Qt.alpha(Theme.accent, 0.32) : Qt.alpha(Theme.surface, 0.78)) : Qt.alpha(Theme.surface, 0.30)
    border.width: 1
    border.color: enabled ? Qt.alpha(Theme.accent, hovered ? 0.72 : (primary ? 0.52 : 0.24)) : Qt.alpha(Theme.text, 0.06)
    opacity: enabled ? 1 : 0.45

    Behavior on scale {
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 140
        }
    }

    RectangularShadow {
        anchors.fill: parent
        visible: root.hovered && root.enabled
        radius: parent.radius
        blur: root.primary ? 22 : 16
        spread: 0
        offset: Qt.vector2d(0, 0)
        color: Qt.alpha(Theme.accent, root.primary ? 0.30 : 0.20)
        cached: true
    }

    ThemedSvgIcon {
        anchors.centerIn: parent
        iconName: root.iconName
        iconSize: root.primary ? 22 : 19
        color: Theme.text
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
