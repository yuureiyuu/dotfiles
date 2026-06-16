pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    property string title: ""
    property string valueText: ""
    property string detailText: ""
    property color accent: Theme.accent
    property var history: []

    radius: 4
    color: Qt.alpha(Theme.surface, 0.72)
    border.width: 1
    border.color: Qt.alpha(Theme.text, 0.08)
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.title
                color: Theme.text
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: root.valueText
                color: root.accent
                font.pixelSize: 22
                font.weight: Font.Bold
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.detailText
            color: Theme.subtext
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        HistoryGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            values: root.history
            lineColor: root.accent
        }
    }
}
