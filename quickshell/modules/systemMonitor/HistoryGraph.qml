pragma ComponentBehavior: Bound

import QtQuick
import "../../services"

Canvas {
    id: root

    property var values: []
    property color lineColor: Theme.accent
    property color fillColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.18)
    property real maxValue: 100

    antialiasing: true
    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        ctx.strokeStyle = Qt.alpha(Theme.text, 0.06);
        ctx.lineWidth = 1;
        for (let i = 1; i < 4; i++) {
            const y = height * i / 4;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            ctx.stroke();
        }

        if (!root.values || root.values.length < 2)
            return;

        const step = width / Math.max(1, root.values.length - 1);
        const points = root.values.map((value, index) => ({
                    x: index * step,
                    y: height - (Math.max(0, Math.min(root.maxValue, value)) / root.maxValue * height)
                }));

        ctx.beginPath();
        ctx.moveTo(points[0].x, height);
        for (const point of points)
            ctx.lineTo(point.x, point.y);
        ctx.lineTo(points[points.length - 1].x, height);
        ctx.closePath();
        ctx.fillStyle = root.fillColor;
        ctx.fill();

        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        for (const point of points)
            ctx.lineTo(point.x, point.y);
        ctx.strokeStyle = root.lineColor;
        ctx.lineWidth = 2;
        ctx.stroke();
    }
}
