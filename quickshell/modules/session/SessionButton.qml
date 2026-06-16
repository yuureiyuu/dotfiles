import QtQuick
import QtQuick.Controls
import "../../services"
import "../../components"

Item {
    id: root
    property string text: ""
    property var iconSource: ""
    property string iconGlyph: ""
    property bool isGif: false
    property real imageScale: 1.0
    signal clicked
    signal hoverEntered
    signal hoverExited
    signal escapePressed

    property bool focused: activeFocus
    property bool hovered: mouseArea.containsMouse
    property bool active: focused || hovered
    focus: true

    width: 100
    height: 100

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 4
        color: root.active ? Theme.surface : Theme.base

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        border.color: root.focused ? Theme.accent : (root.hovered ? Theme.subtext : Theme.border)
        border.width: 1

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Item {
        id: content
        anchors.centerIn: parent
        width: 64
        height: 64
        scale: root.iconGlyph.length ? 1.0 : root.imageScale * (root.active ? 1.1 : 1.0)
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: root.isGif ? gifComponent : (root.iconGlyph.length ? iconComponent : imgComponent)
        }
    }

    Component {
        id: iconComponent
        LucideIcon {
            anchors.fill: parent
            icon: root.iconGlyph
            iconSize: root.active ? 60 : 54
            color: root.active ? Theme.iconActive : Theme.icon

            Behavior on iconSize {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    Component {
        id: imgComponent
        Image {
            source: root.iconSource
            sourceSize.width: 160
            sourceSize.height: 160
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
    }

    Component {
        id: gifComponent
        AnimatedImage {
            source: root.iconSource
            sourceSize.width: 160
            sourceSize.height: 160
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onEntered: root.hoverEntered()
        onExited: root.hoverExited()
    }

    // Keyboard navigation support
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.escapePressed();
            event.accepted = true;
        }
    }
}
