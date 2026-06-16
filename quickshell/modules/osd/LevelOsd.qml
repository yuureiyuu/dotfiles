pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    property bool open: false
    property bool closing: false
    property bool changeTrackingReady: false
    property real revealProgress: 0
    readonly property bool visibleState: open || closing || revealProgress > 0.001

    function show() {
        hideTimer.restart();
        if (open && !closing)
            return;

        revealAnimation.stop();
        closing = false;
        open = true;
        revealAnimation.to = 1;
        revealAnimation.duration = Math.max(1, 210 * (1 - revealProgress));
        revealAnimation.start();
    }

    function close() {
        if (closing || !open)
            return;

        revealAnimation.stop();
        open = false;
        closing = true;
        revealAnimation.to = 0;
        revealAnimation.duration = Math.max(1, 180 * revealProgress);
        revealAnimation.start();
    }

    anchors {
        top: true
        bottom: true
        left: true
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    visible: root.visibleState
    implicitWidth: 126
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:level-osd"

    mask: Region {
        item: panel
    }

    Connections {
        target: Audio

        function onOutputChangedByUser() {
            root.show();
        }

        function onMutedChanged() {
            if (root.changeTrackingReady)
                root.show();
        }

        function onVolumeChanged() {
            if (root.changeTrackingReady)
                root.show();
        }
    }

    Connections {
        target: Brightness

        function onChangedByUser() {
            root.show();
        }

        function onValueChanged() {
            if (root.changeTrackingReady)
                root.show();
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: false
        onTriggered: root.changeTrackingReady = true
    }

    Timer {
        id: hideTimer

        interval: 1350
        repeat: false
        onTriggered: root.close()
    }

    RectangularShadow {
        anchors.fill: panel
        radius: panel.radius
        blur: 18
        spread: 0
        offset: Qt.vector2d(2, 3)
        color: "#38000000"
        cached: true
    }

    Rectangle {
        id: panel

        width: 104
        height: 254
        x: -width + 14 + root.revealProgress * width
        anchors.verticalCenter: parent.verticalCenter
        radius: 8
        color: Qt.alpha(Theme.mantle, 0.94)
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.28)

        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 1
            color: Qt.alpha(Theme.text, 0.08)
        }

        Row {
            anchors.centerIn: parent
            spacing: 14

            VerticalLevelSlider {
                iconName: "sun"
                value: Brightness.value
                fillColor: Theme.accent2
            }

            VerticalLevelSlider {
                iconName: Audio.volumeIcon(Audio.volume, Audio.muted)
                value: Audio.muted ? 0 : Audio.volume
                to: 1.5
                fillColor: Theme.accent
            }
        }
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        duration: 210
        easing.type: Easing.OutCubic

        onFinished: {
            if (root.revealProgress <= 0.001) {
                root.revealProgress = 0;
                root.closing = false;
            } else if (root.revealProgress >= 0.999) {
                root.revealProgress = 1;
            }
        }
    }
}
