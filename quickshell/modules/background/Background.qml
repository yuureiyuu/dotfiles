import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    readonly property bool active: SettingsService.wallpaperDim || SettingsService.desktopClock

    visible: active
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: false
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:background"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {}

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, SettingsService.wallpaperDim ? 0.26 : 0)

        Behavior on color {
            ColorAnimation {
                duration: 180
            }
        }
    }

    ColumnLayout {
        visible: SettingsService.desktopClock
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 42
        }
        spacing: 2
        opacity: SettingsService.desktopClock ? 1 : 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clockTimer.currentDate, SettingsService.clock24h ? "HH:mm" : "hh:mm AP")
            color: Qt.alpha(Theme.text, 0.70)
            font.family: "Sawarabi Gothic"
            font.pixelSize: 44
            font.weight: Font.Normal
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clockTimer.currentDate, "yyyy/M/d")
            color: Qt.alpha(Theme.subtext, 0.70)
            font.family: "Sawarabi Gothic"
            font.pixelSize: 14
        }
    }

    Timer {
        id: clockTimer

        property var currentDate: new Date()

        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: currentDate = new Date()
    }
}
