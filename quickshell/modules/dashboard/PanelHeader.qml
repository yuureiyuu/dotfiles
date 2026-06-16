import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"

RowLayout {
    id: root

    required property string iconName
    required property string title

    spacing: 9

    ThemedSvgIcon {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        iconName: root.iconName
        iconSize: 20
        color: Theme.iconActive
    }

    Text {
        Layout.fillWidth: true
        text: root.title
        color: Theme.text
        font.pixelSize: 15
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }
}
