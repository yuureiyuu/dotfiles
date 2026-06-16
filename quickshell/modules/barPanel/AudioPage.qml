pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"

Flickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        width: root.width
        spacing: 10

        Section {
            title: "Output"
            iconName: Audio.volumeIcon(Audio.volume, Audio.muted)

            SliderRow {
                label: Audio.ready ? "Master volume" : "Audio sink unavailable"
                iconName: Audio.volumeIcon(Audio.volume, Audio.muted)
                value: Audio.volume
                to: 1.5
                enabledState: Audio.ready
                onMoved: value => Audio.setVolume(value)
            }

            ToggleRow {
                label: "Mute output"
                checked: Audio.muted
                enabledState: Audio.ready
                onToggled: checked => Audio.setMuted(checked)
            }
        }

        Section {
            title: "Output Device"
            iconName: "speaker"

            Repeater {
                model: Audio.outputDevices

                DeviceRow {
                    required property var modelData

                    iconName: "speaker"
                    title: Audio.displayName(modelData)
                    subtitle: Audio.sink?.id === modelData.id ? "Current output" : "Available"
                    active: Audio.sink?.id === modelData.id
                    actionIcon: Audio.sink?.id === modelData.id ? "check" : "link"
                    enabledState: true
                    onClicked: Audio.setDefaultSink(modelData)
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Audio.outputDevices.length === 0
                text: "No output devices found."
                color: Theme.subtext
                font.pixelSize: 12
            }
        }

        Section {
            title: "Applications"
            iconName: "sticker"

            Repeater {
                model: Audio.appStreams

                SliderRow {
                    required property var modelData

                    label: Audio.displayName(modelData)
                    iconName: Audio.volumeIcon(modelData.audio.volume, modelData.audio.muted)
                    value: modelData.audio.volume
                    to: 1.5
                    onMoved: value => Audio.setStreamVolume(modelData, value)
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Audio.appStreams.length === 0
                text: "No application audio streams."
                color: Theme.subtext
                font.pixelSize: 12
            }
        }
    }
}
