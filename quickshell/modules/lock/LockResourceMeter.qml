pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    property real uiScale: 1
    property string label: ""
    property string valueText: ""
    property real value: 0
    property bool active: true
    property color fillColor: Theme.accent

    Layout.fillWidth: true
    Layout.preferredHeight: 48 * root.uiScale
    radius: 4
    color: Theme.base
    border.width: 1
    border.color: Theme.border
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10 * root.uiScale
        spacing: 6 * root.uiScale

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.label
                color: root.active ? "white" : Theme.subtext
                font.pixelSize: 13 * root.uiScale
                font.weight: Font.Medium
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: root.valueText
                color: Theme.subtext
                font.pixelSize: 12 * root.uiScale
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6 * root.uiScale
            radius: 2
            color: Theme.mantle

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
                height: parent.height
                radius: 2
                color: root.active ? root.fillColor : Theme.border
            }
        }
    }
}
