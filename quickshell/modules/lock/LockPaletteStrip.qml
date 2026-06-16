pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

Column {
    id: root

    property real uiScale: 1

    spacing: 10 * root.uiScale

    Repeater {
        model: [Theme.swatch0, Theme.swatch1, Theme.swatch2, Theme.swatch3, Theme.swatch4, Theme.swatch5, Theme.swatch6, Theme.swatch7]

        Item {
            required property color modelData
            required property int index

            width: 30 * root.uiScale
            height: 30 * root.uiScale

            Rectangle {
                id: diamond

                anchors.centerIn: parent
                width: 19 * root.uiScale
                height: 19 * root.uiScale
                radius: 3
                rotation: 45
                color: modelData
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.28)
                antialiasing: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: parent.width
                    height: parent.height / 2
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.16)
                }
            }
        }
    }
}
