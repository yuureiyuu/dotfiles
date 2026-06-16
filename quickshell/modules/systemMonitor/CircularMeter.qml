pragma ComponentBehavior: Bound

import QtQuick
import "../../services"

Item {
    id: root

    property real value: 0
    property real animatedValue: value
    property color accent: Theme.accent
    property color trackColor: Qt.alpha(Theme.text, 0.08)
    property string text: `${Math.round(value)}%`

    implicitWidth: 48
    implicitHeight: 48

    onValueChanged: animatedValue = value

    Behavior on animatedValue {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            const size = Math.min(width, height);
            const center = size / 2;
            const lineWidth = 5;
            const radius = center - lineWidth / 2 - 1;
            const start = -Math.PI / 2;
            const end = start + Math.PI * 2 * Math.max(0, Math.min(100, root.animatedValue)) / 100;

            ctx.clearRect(0, 0, width, height);
            ctx.lineCap = "round";
            ctx.lineWidth = lineWidth;

            ctx.beginPath();
            ctx.arc(width / 2, height / 2, radius, 0, Math.PI * 2);
            ctx.strokeStyle = root.trackColor;
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(width / 2, height / 2, radius, start, end);
            ctx.strokeStyle = root.accent;
            ctx.stroke();
        }

        Connections {
            target: root
            function onAnimatedValueChanged() {
                canvas.requestPaint();
            }
            function onAccentChanged() {
                canvas.requestPaint();
            }
            function onTrackColorChanged() {
                canvas.requestPaint();
            }
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Text {
        anchors.centerIn: parent
        text: root.text
        color: root.accent
        font.pixelSize: 10
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
