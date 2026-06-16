pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../components"
import "../../services"

Rectangle {
    id: root

    property real uiScale: 1
    property Item blurSource: null

    radius: 4
    color: Qt.alpha(Theme.base, 0.76)
    border.width: 1
    border.color: Qt.alpha(Theme.text, 0.14)
    clip: true

    Item {
        anchors.fill: parent
        clip: true

        ShaderEffectSource {
            id: weatherBlurSource

            anchors.fill: parent
            sourceItem: root.blurSource
            sourceRect: Qt.rect(root.x, root.y, root.width, root.height)
            visible: false
            live: true
            recursive: false
        }

        MultiEffect {
            anchors.fill: parent
            source: weatherBlurSource
            visible: root.blurSource !== null
            maskEnabled: true
            maskSource: weatherMask
            blurEnabled: true
            blur: 0.55
            blurMax: 26
            saturation: 0.96
            brightness: -0.06
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.color
        }
    }

    Item {
        id: weatherMask

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "white"
        }
    }

    RowLayout {
        z: 2
        anchors.fill: parent
        anchors.leftMargin: 16 * root.uiScale
        anchors.rightMargin: 16 * root.uiScale
        spacing: 13 * root.uiScale

        Rectangle {
            Layout.preferredWidth: 50 * root.uiScale
            Layout.preferredHeight: 50 * root.uiScale
            radius: 4
            color: Qt.alpha(Theme.accent, 0.20)
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.32)

            ThemedSvgIcon {
                anchors.centerIn: parent
                iconName: Weather.iconName
                iconSize: 27 * root.uiScale
                color: Theme.text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1 * root.uiScale

            Text {
                Layout.fillWidth: true
                text: Weather.city
                color: Theme.text
                font.pixelSize: 16 * root.uiScale
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: Weather.condition
                color: Qt.alpha(Theme.text, 0.64)
                font.pixelSize: 12 * root.uiScale
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Text {
            text: Weather.temperature
            color: Theme.text
            font.pixelSize: 34 * root.uiScale
            font.weight: Font.DemiBold
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 38 * root.uiScale
            color: Qt.alpha(Theme.text, 0.12)
        }

        ColumnLayout {
            spacing: 2 * root.uiScale

            Text {
                text: `Feels ${Weather.feelsLike}`
                color: Qt.alpha(Theme.text, 0.68)
                font.pixelSize: 11 * root.uiScale
                font.family: "monospace"
            }

            Text {
                text: `${Weather.humidity} / ${Weather.wind}`
                color: Qt.alpha(Theme.text, 0.54)
                font.pixelSize: 11 * root.uiScale
                font.family: "monospace"
            }
        }
    }

    Rectangle {
        z: 3
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.14)
    }
}
