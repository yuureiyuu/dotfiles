import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

ColumnLayout {
    id: root

    required property string title
    property string iconName: "circle-alert"
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    spacing: 8

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: contentColumn.implicitHeight + header.implicitHeight + 30
        radius: 6
        color: Qt.alpha(Theme.mantle, 0.74)
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                id: header
                Layout.fillWidth: true
                spacing: 8

                ThemedSvgIcon {
                    iconName: root.iconName
                    iconSize: 17
                    color: Theme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
            }

            ColumnLayout {
                id: contentColumn
                Layout.fillWidth: true
                spacing: 8
            }
        }
    }
}
