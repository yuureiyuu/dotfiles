import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root

    required property string iconName
    property color color: Theme.icon
    property int iconSize: 24
    readonly property string iconFile: iconName === "stiker" ? "sticker" : iconName
    readonly property string iconPath: Quickshell.shellPath(`assets/icons/svg/${iconFile}.svg`)

    implicitWidth: iconSize
    implicitHeight: iconSize

    function colorToHex(value) {
        const r = Math.round(value.r * 255).toString(16).padStart(2, "0");
        const g = Math.round(value.g * 255).toString(16).padStart(2, "0");
        const b = Math.round(value.b * 255).toString(16).padStart(2, "0");
        return `#${r}${g}${b}`;
    }

    function themedSource() {
        const raw = svgFile.text();
        if (!raw.length)
            return "";

        const themed = raw.replace(/stroke="[^"]*"/g, `stroke="${colorToHex(root.color)}"`);
        return `data:image/svg+xml;utf8,${encodeURIComponent(themed)}`;
    }

    Image {
        anchors.fill: parent
        source: root.themedSource()
        sourceSize.width: root.iconSize * 2
        sourceSize.height: root.iconSize * 2
        smooth: true
        mipmap: true
    }

    FileView {
        id: svgFile

        path: root.iconPath
        watchChanges: true
        onFileChanged: reload()
    }
}
