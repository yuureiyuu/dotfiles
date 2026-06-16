import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: root

    property bool horizontal: false
    implicitWidth: horizontal ? horizontalClock.implicitWidth : verticalClock.implicitWidth
    implicitHeight: horizontal ? horizontalClock.implicitHeight : verticalClock.implicitHeight

    // timer
    Timer {
        id: timeSource
        interval: 1000
        running: true
        repeat: true
        property var currentDate: new Date()
        onTriggered: currentDate = new Date()
    }

    ColumnLayout {
        id: verticalClock

        visible: !root.horizontal
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -5
        spacing: 1

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: -10

            Text {
                text: SettingsService.clock24h ? Qt.formatDateTime(timeSource.currentDate, "HH") : (timeSource.currentDate.getHours() % 12 || 12).toString().padStart(2, "0")
                font.family: "Sawarabi Gothic"
                font.pixelSize: 47
                font.weight: Font.Normal
                color: Theme.text
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: Qt.formatDateTime(timeSource.currentDate, "mm")
                font.family: "Sawarabi Gothic"
                font.pixelSize: 47
                font.weight: Font.Normal
                color: Theme.text
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                visible: !SettingsService.clock24h
                text: Qt.formatDateTime(timeSource.currentDate, "AP")
                font.family: "Sawarabi Gothic"
                font.pixelSize: 14
                font.weight: Font.Normal
                color: Theme.text
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            Layout.topMargin: -2
            Text {
                text: Qt.formatDateTime(timeSource.currentDate, "yyyy'年'")
                font.family: "Sawarabi Gothic"
                font.pixelSize: 12
                font.weight: Font.Normal
                color: Theme.subtext
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: Qt.formatDateTime(timeSource.currentDate, "M'月'd'日'")
                font.family: "Sawarabi Gothic"
                font.pixelSize: 12
                font.weight: Font.Normal
                color: Theme.subtext
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    RowLayout {
        id: horizontalClock

        visible: root.horizontal
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: SettingsService.clock24h ? Qt.formatDateTime(timeSource.currentDate, "HH:mm") : Qt.formatDateTime(timeSource.currentDate, "hh:mm AP")
            font.family: "Sawarabi Gothic"
            font.pixelSize: 24
            font.weight: Font.Normal
            color: Theme.text
        }

        Text {
            text: Qt.formatDateTime(timeSource.currentDate, "yyyy/M/d")
            font.family: "Sawarabi Gothic"
            font.pixelSize: 12
            color: Theme.subtext
        }
    }
}
