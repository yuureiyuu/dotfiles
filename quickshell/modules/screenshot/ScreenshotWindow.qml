pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    required property var screenshot

    property real pressX: 0
    property real pressY: 0
    property real dragX: 0
    property real dragY: 0
    property bool dragging: false
    property bool armed: false
    property bool capturePending: false
    property string pendingGeometry: ""
    property string pendingFile: ""

    readonly property real rx: Math.min(pressX, dragX)
    readonly property real ry: Math.min(pressY, dragY)
    readonly property real rw: Math.abs(dragX - pressX)
    readonly property real rh: Math.abs(dragY - pressY)
    readonly property bool hasSelection: rw > 2 && rh > 2
    readonly property color accentColor: Theme.accent

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function screenshotFile() {
        const home = Quickshell.env("HOME") || "/tmp";
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-hhmmss-zzz");
        return `${home}/Pictures/screenshot-${stamp}.png`;
    }

    function buildGeometry() {
        const gx = Math.round((screen ? screen.x : 0) + rx);
        const gy = Math.round((screen ? screen.y : 0) + ry);
        const gw = Math.max(1, Math.round(rw));
        const gh = Math.max(1, Math.round(rh));
        return `${gx},${gy} ${gw}x${gh}`;
    }

    function finishCapture() {
        if (rw < 8 || rh < 8) {
            screenshot.close();
            return;
        }

        pendingGeometry = buildGeometry();
        pendingFile = screenshotFile();
        capturePending = true;
        captureTimer.restart();
    }

    function runCapture() {
        const file = shellQuote(pendingFile);
        const geometry = shellQuote(pendingGeometry);
        const command = `mkdir -p "$HOME/Pictures" && grim -g ${geometry} ${file} && wl-copy --type image/png < ${file} && { command -v notify-send >/dev/null 2>&1 && notify-send -a quickshell -i ${file} "Screenshot saved" ${shellQuote(pendingFile)} || true; }`;
        Quickshell.execDetached(["sh", "-c", command]);
        screenshot.close();
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Timer {
        id: captureTimer

        interval: 70
        repeat: false
        onTriggered: root.runCapture()
    }

    Item {
        id: visibleLayer

        anchors.fill: parent
        visible: !capturePending
        opacity: screenshot.closing ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.base
            opacity: root.hasSelection ? 0 : 0.42
        }

        Repeater {
            model: [
                { x: 0, y: 0, w: root.width, h: root.ry },
                { x: 0, y: root.ry + root.rh, w: root.width, h: root.height - root.ry - root.rh },
                { x: 0, y: root.ry, w: root.rx, h: root.rh },
                { x: root.rx + root.rw, y: root.ry, w: root.width - root.rx - root.rw, h: root.rh }
            ]

            Rectangle {
                required property var modelData

                x: Math.max(0, modelData.x)
                y: Math.max(0, modelData.y)
                width: Math.max(0, modelData.w)
                height: Math.max(0, modelData.h)
                visible: root.hasSelection
                color: Theme.base
                opacity: 0.48
            }
        }

        Rectangle {
            id: selectionBox

            x: root.rx
            y: root.ry
            width: root.rw
            height: root.rh
            visible: root.hasSelection
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.95)

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.42)
            }

            Repeater {
                model: [
                    { x: -1, y: -1, ax: 0, ay: 0 },
                    { x: selectionBox.width - 31, y: -1, ax: 1, ay: 0 },
                    { x: -1, y: selectionBox.height - 31, ax: 0, ay: 1 },
                    { x: selectionBox.width - 31, y: selectionBox.height - 31, ax: 1, ay: 1 }
                ]

                Item {
                    required property var modelData

                    x: modelData.x
                    y: modelData.y
                    width: 32
                    height: 32

                    Rectangle {
                        x: 0
                        y: modelData.ay ? 29 : 0
                        width: 32
                        height: 3
                        color: Theme.accentHex
                        opacity: 0.95
                    }

                    Rectangle {
                        x: modelData.ax ? 29 : 0
                        y: 0
                        width: 3
                        height: 32
                        color: Theme.accentHex
                        opacity: 0.95
                    }
                }
            }

            Text {
                x: 8
                y: -22
                text: `${Math.round(root.rw)}x${Math.round(root.rh)}`
                color: Theme.accentHex
                font.family: "monospace"
                font.pixelSize: 11
                visible: root.rw > 44 && root.ry > 24
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            hoverEnabled: true

            onPressed: event => {
                root.armed = true;
                root.dragging = true;
                root.pressX = event.x;
                root.pressY = event.y;
                root.dragX = event.x;
                root.dragY = event.y;
            }

            onPositionChanged: event => {
                if (!root.dragging)
                    return;

                root.dragX = Math.max(0, Math.min(width, event.x));
                root.dragY = Math.max(0, Math.min(height, event.y));
            }

            onReleased: {
                if (!root.armed)
                    return;

                root.dragging = false;
                root.armed = false;
                root.finishCapture();
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: screenshot.close()
        Component.onCompleted: forceActiveFocus()
    }
}
