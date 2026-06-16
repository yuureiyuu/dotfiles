pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../components"
import "../../services"

Rectangle {
    id: root

    property real uiScale: 1

    radius: 4
    color: Qt.alpha(Theme.base, 0.76)
    border.width: 1
    border.color: Qt.alpha(Theme.text, 0.16)
    clip: true

    Item {
        id: backgroundLayer

        anchors.fill: parent
        clip: true

        Image {
            id: albumBackdrop

            property bool useFallback: false
            property int artIndex: 0
            readonly property var artSources: NowPlaying.artUrls

            anchors.fill: parent
            source: useFallback ? NowPlaying.fallbackArtUrl : (artSources.length > artIndex ? artSources[artIndex] : NowPlaying.artUrl)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: 900
            sourceSize.height: 900
            visible: false
            onStatusChanged: {
                if (status !== Image.Error || useFallback)
                    return;

                if (artIndex + 1 < artSources.length)
                    artIndex += 1;
                else if (NowPlaying.fallbackArtUrl.length)
                    useFallback = true;
            }

            Connections {
                target: NowPlaying

                function onArtRevisionChanged() {
                    albumBackdrop.artIndex = 0;
                    albumBackdrop.useFallback = false;
                }
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: albumBackdrop
            visible: albumBackdrop.status === Image.Ready
            blurEnabled: true
            blur: 1
            blurMax: 42
            saturation: 0.62
            brightness: -0.22
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.mantle, 0.66)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Theme.base, 0.90)
                }
            }
        }

        Canvas {
            id: waveCanvas

            property real phase: 0
            readonly property real waveVolume: Math.max(0.08, Math.min(1, NowPlaying.volume || 0.55))

            function cssColor(value) {
                const r = Math.round(value.r * 255).toString(16).padStart(2, "0");
                const g = Math.round(value.g * 255).toString(16).padStart(2, "0");
                const b = Math.round(value.b * 255).toString(16).padStart(2, "0");
                return `#${r}${g}${b}`;
            }

            anchors.fill: parent
            opacity: NowPlaying.isPlaying ? 0.34 : 0.16
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const center = height * 0.58;
                const amp = (NowPlaying.isPlaying ? 15 : 6) * waveVolume;
                for (let line = 0; line < 3; line++) {
                    ctx.beginPath();
                    ctx.lineWidth = 1.35;
                    ctx.strokeStyle = line === 0 ? cssColor(Theme.accent) : (line === 1 ? cssColor(Theme.accent2) : cssColor(Theme.text));
                    ctx.globalAlpha = line === 0 ? 0.34 : (line === 1 ? 0.22 : 0.11);
                    for (let x = 0; x <= width; x += 8) {
                        const y = center + Math.sin((x / width) * Math.PI * 2.2 + phase + line * 0.9) * amp + Math.sin((x / width) * Math.PI * 5.6 + phase * 0.58 + line) * amp * 0.34;
                        if (x === 0)
                            ctx.moveTo(x, y);
                        else
                            ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
                ctx.globalAlpha = 1;
            }

            Timer {
                interval: 66
                repeat: true
                running: NowPlaying.isPlaying
                onTriggered: {
                    waveCanvas.phase += 0.032 + waveCanvas.waveVolume * 0.028;
                    waveCanvas.requestPaint();
                }
            }

            Component.onCompleted: requestPaint()
        }
    }

    RowLayout {
        z: 2
        anchors.fill: parent
        anchors.margins: 18 * root.uiScale
        spacing: 18 * root.uiScale

        Rectangle {
            Layout.preferredWidth: 132 * root.uiScale
            Layout.preferredHeight: 132 * root.uiScale
            radius: 4
            color: Qt.alpha(Theme.surface, 0.82)
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.14)
            clip: true

            Image {
                id: albumCover

                property bool useFallback: false
                property int artIndex: 0
                readonly property var artSources: NowPlaying.artUrls

                anchors.fill: parent
                source: useFallback ? NowPlaying.fallbackArtUrl : (artSources.length > artIndex ? artSources[artIndex] : NowPlaying.artUrl)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                mipmap: false
                smooth: true
                sourceSize.width: 900
                sourceSize.height: 900
                visible: status === Image.Ready
                onStatusChanged: {
                    if (status !== Image.Error || useFallback)
                        return;

                    if (artIndex + 1 < artSources.length)
                        artIndex += 1;
                    else if (NowPlaying.fallbackArtUrl.length)
                        useFallback = true;
                }

                Connections {
                    target: NowPlaying

                    function onArtRevisionChanged() {
                        albumCover.artIndex = 0;
                        albumCover.useFallback = false;
                    }
                }
            }

            ThemedSvgIcon {
                anchors.centerIn: parent
                visible: albumCover.status !== Image.Ready
                iconName: NowPlaying.isPlaying ? "disc-album" : "music"
                iconSize: 46 * root.uiScale
                color: Theme.iconActive
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 9 * root.uiScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.uiScale

                ThemedSvgIcon {
                    Layout.preferredWidth: 16 * root.uiScale
                    Layout.preferredHeight: 16 * root.uiScale
                    iconName: NowPlaying.isPlaying ? "radio-receiver" : "music-2"
                    iconSize: 17 * root.uiScale
                    color: Theme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: NowPlaying.player.length ? NowPlaying.player : "Media"
                    color: Qt.alpha(Theme.text, 0.70)
                    font.pixelSize: 12 * root.uiScale
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Text {
                Layout.fillWidth: true
                text: NowPlaying.title.length ? NowPlaying.title : "Nothing is playing"
                color: Theme.text
                font.pixelSize: 23 * root.uiScale
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: NowPlaying.artist.length ? NowPlaying.artist : "Open a player and it will appear here"
                color: Qt.alpha(Theme.text, 0.62)
                font.pixelSize: 14 * root.uiScale
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8 * root.uiScale
                spacing: 11 * root.uiScale

                MediaControlButton {
                    iconName: "skip-back"
                    uiScale: root.uiScale
                    enabled: NowPlaying.activePlayer?.canGoPrevious ?? false
                    onClicked: NowPlaying.activePlayer?.previous()
                }

                MediaControlButton {
                    iconName: NowPlaying.isPlaying ? "pause" : "play"
                    uiScale: root.uiScale
                    primary: true
                    enabled: (NowPlaying.activePlayer?.canPause ?? false) || (NowPlaying.activePlayer?.canPlay ?? false)
                    onClicked: NowPlaying.activePlayer?.togglePlaying()
                }

                MediaControlButton {
                    iconName: "skip-forward"
                    uiScale: root.uiScale
                    enabled: NowPlaying.activePlayer?.canGoNext ?? false
                    onClicked: NowPlaying.activePlayer?.next()
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: NowPlaying.formatTime(NowPlaying.position)
                    color: Qt.alpha(Theme.text, 0.58)
                    font.pixelSize: 11 * root.uiScale
                    font.family: "monospace"
                }

                Rectangle {
                    Layout.preferredWidth: 190 * root.uiScale
                    Layout.preferredHeight: 7 * root.uiScale
                    radius: 3
                    color: Qt.alpha(Theme.text, 0.16)
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(parent.height, parent.width * NowPlaying.progress)
                        radius: 3
                        color: Theme.accent
                    }
                }

                Text {
                    text: NowPlaying.length > 0 ? NowPlaying.formatTime(NowPlaying.length) : "0:00"
                    color: Qt.alpha(Theme.text, 0.58)
                    font.pixelSize: 11 * root.uiScale
                    font.family: "monospace"
                }
            }
        }
    }

    component MediaControlButton: Rectangle {
        id: button

        required property string iconName
        property bool primary: false
        property real uiScale: 1
        signal clicked

        readonly property bool hovered: mouseArea.containsMouse

        implicitWidth: (primary ? 46 : 40) * uiScale
        implicitHeight: (primary ? 46 : 40) * uiScale
        radius: 4
        color: enabled ? (primary ? Qt.alpha(Theme.accent, hovered ? 0.38 : 0.32) : Qt.alpha(Theme.text, hovered ? 0.16 : 0.12)) : Qt.alpha(Theme.text, 0.06)
        border.width: 1
        border.color: enabled ? Qt.alpha(Theme.accent, hovered ? 0.72 : (primary ? 0.52 : 0.24)) : Qt.alpha(Theme.text, 0.05)
        opacity: enabled ? 1 : 0.45
        scale: hovered && enabled ? 1.06 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        ThemedSvgIcon {
            anchors.centerIn: parent
            iconName: button.iconName
            iconSize: (button.primary ? 21 : 18) * button.uiScale
            color: Theme.text
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
