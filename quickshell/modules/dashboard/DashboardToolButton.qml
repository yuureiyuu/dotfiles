import QtQuick
import "../../components"
import "../../services"

Rectangle {
    id: root

    required property string iconName
    readonly property color dangerColor: "#ff6b6b"
    property bool primary: false
    property bool danger: false
    property bool colorfulPressEffect: false
    signal clicked

    implicitWidth: 34
    implicitHeight: 34
    radius: 4
    clip: true
    color: primary ? Qt.alpha(Theme.accent, 0.28) : Qt.alpha(Theme.surface2, 0.34)
    border.width: 1
    border.color: danger ? Qt.alpha(dangerColor, 0.34) : Qt.alpha(Theme.accent, primary ? 0.46 : 0.16)

    Rectangle {
        id: pressPulse

        anchors.centerIn: parent
        width: Math.max(root.width, root.height) * 1.6
        height: width
        radius: width / 2
        scale: 0.2
        opacity: 0
        color: Theme.mixColor(Theme.accent, Theme.accent2, 0.5)
    }

    ThemedSvgIcon {
        anchors.centerIn: parent
        iconName: root.iconName
        iconSize: 17
        color: root.danger ? "#ff9a9a" : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.colorfulPressEffect) {
                pressPulseAnimation.stop();
                pressPulseAnimation.start();
            }
            root.clicked();
        }
    }

    SequentialAnimation {
        id: pressPulseAnimation

        ParallelAnimation {
            NumberAnimation {
                target: pressPulse
                property: "opacity"
                from: 0.48
                to: 0
                duration: 420
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: pressPulse
                property: "scale"
                from: 0.2
                to: 1
                duration: 420
                easing.type: Easing.OutCubic
            }
        }
    }
}
