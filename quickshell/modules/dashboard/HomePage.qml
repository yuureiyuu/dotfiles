pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import "../../components"
import "../../services"

Item {
    id: root

    required property string osName
    required property string wmName

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 14
        columnSpacing: 14

        DashboardPanel {
            visible: SettingsService.systemStatsService
            Layout.preferredHeight: visible ? 230 : 0
            Layout.fillWidth: true
            Layout.preferredWidth: 420

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                PanelHeader {
                    Layout.fillWidth: true
                    iconName: "circle-user-round"
                    title: SettingsService.t("System")
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: [
                            {
                                "icon": "circle-user",
                                "label": SettingsService.t("User"),
                                "value": SystemStats.username || "unknown"
                            },
                            {
                                "icon": "laptop",
                                "label": "OS",
                                "value": root.osName
                            },
                            {
                                "icon": "panels-top-left",
                                "label": "WM",
                                "value": root.wmName
                            },
                            {
                                "icon": "timer",
                                "label": SettingsService.t("Uptime"),
                                "value": SystemStats.uptimeText || "0m"
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            radius: 4
                            color: Qt.alpha(Theme.surface, 0.78)
                            border.width: 1
                            border.color: Qt.alpha(Theme.border, 0.70)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                ThemedSvgIcon {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    iconName: modelData.icon
                                    iconSize: 22
                                    color: Theme.iconActive
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        color: Theme.subtext
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.value
                                        color: Theme.text
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        DashboardPanel {
            Layout.fillWidth: true
            Layout.preferredWidth: 420
            Layout.preferredHeight: 230
            clip: true

            AnimatedImage {
                anchors.fill: parent
                anchors.margins: 1
                source: Quickshell.shellPath("assets/kurumi.gif")
                fillMode: Image.PreserveAspectCrop
                playing: root.visible
                cache: false
                smooth: true
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.base, 0.06)
            }
        }

        DashboardPanel {
            visible: SettingsService.nowPlayingService
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.columnSpan: 2
            clip: true
            border.color: Qt.alpha(Theme.accent, 0.20)

            Image {
                id: albumArtSource

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

                    if (artIndex + 1 < artSources.length) {
                        artIndex += 1;
                    } else if (NowPlaying.fallbackArtUrl.length) {
                        useFallback = true;
                    }
                }

                Connections {
                    target: NowPlaying

                    function onArtRevisionChanged() {
                        albumArtSource.artIndex = 0;
                        albumArtSource.useFallback = false;
                    }
                }
            }

            MultiEffect {
                anchors.fill: parent
                source: albumArtSource
                visible: albumArtSource.status === Image.Ready
                blurEnabled: true
                blurMax: 48
                blur: 1
                saturation: 0.52
                brightness: -0.24
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.mantle, 0.84)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.base, 0.95)
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
                opacity: NowPlaying.isPlaying ? 0.34 : 0.12
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    const center = height * 0.56;
                    const amp = (NowPlaying.isPlaying ? 18 : 7) * waveVolume;
                    const lines = 3;
                    for (let line = 0; line < lines; line++) {
                        ctx.beginPath();
                        ctx.lineWidth = 1.4;
                        ctx.strokeStyle = line === 0 ? cssColor(Theme.accent) : (line === 1 ? cssColor(Theme.accent2) : cssColor(Theme.text));
                        ctx.globalAlpha = line === 0 ? 0.34 : (line === 1 ? 0.22 : 0.10);
                        for (let x = 0; x <= width; x += 8) {
                            const y = center + Math.sin((x / width) * Math.PI * 2.1 + phase + line * 0.9) * amp + Math.sin((x / width) * Math.PI * 5.4 + phase * 0.58 + line) * amp * 0.34;
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
                    running: root.visible && NowPlaying.isPlaying
                    onTriggered: {
                        waveCanvas.phase += 0.032 + waveCanvas.waveVolume * 0.028;
                        waveCanvas.requestPaint();
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 240
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 22
                anchors.bottomMargin: 50
                spacing: 20

                Rectangle {
                    Layout.preferredWidth: 126
                    Layout.preferredHeight: 126
                    radius: 7
                    color: Qt.alpha(Theme.surface, 0.72)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.34)
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
                        mipmap: true
                        smooth: true
                        sourceSize.width: 512
                        sourceSize.height: 512
                        visible: status === Image.Ready
                        onStatusChanged: {
                            if (status !== Image.Error || useFallback)
                                return;

                            if (artIndex + 1 < artSources.length) {
                                artIndex += 1;
                            } else if (NowPlaying.fallbackArtUrl.length) {
                                useFallback = true;
                            }
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
                        iconSize: 52
                        color: Theme.iconActive
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Item {
                        Layout.fillHeight: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: NowPlaying.title.length ? NowPlaying.title : SettingsService.t("Nothing is playing")
                        color: Theme.text
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: NowPlaying.artist.length ? NowPlaying.artist : (NowPlaying.player.length ? NowPlaying.player : SettingsService.t("MPRIS player"))
                        color: Theme.subtext
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.topMargin: 8
                        spacing: 12

                        MediaButton {
                            iconName: "skip-back"
                            enabled: NowPlaying.activePlayer?.canGoPrevious ?? false
                            onClicked: NowPlaying.activePlayer?.previous()
                        }

                        MediaButton {
                            iconName: NowPlaying.isPlaying ? "pause" : "play"
                            enabled: (NowPlaying.activePlayer?.canPause ?? false) || (NowPlaying.activePlayer?.canPlay ?? false)
                            primary: true
                            onClicked: NowPlaying.activePlayer?.togglePlaying()
                        }

                        MediaButton {
                            iconName: "skip-forward"
                            enabled: NowPlaying.activePlayer?.canGoNext ?? false
                            onClicked: NowPlaying.activePlayer?.next()
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 18
                    rightMargin: 18
                    bottomMargin: 15
                }
                spacing: 12

                Text {
                    Layout.preferredWidth: 46
                    text: NowPlaying.formatTime(NowPlaying.position)
                    color: Theme.subtext
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignLeft
                }

                Rectangle {
                    id: progressTrack

                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Qt.alpha(Theme.surface, 0.56)
                    clip: true

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: Math.max(parent.height, parent.width * NowPlaying.progress)
                        radius: parent.radius
                        color: Qt.alpha(Theme.accent, 0.72)

                        Behavior on width {
                            enabled: !progressMouse.dragging
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, parent.width * NowPlaying.progress - width / 2))
                        color: Theme.text
                        border.width: 2
                        border.color: Theme.accent
                        opacity: progressMouse.containsMouse || progressMouse.dragging ? 1 : 0.72

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }

                    MouseArea {
                        id: progressMouse

                        property bool dragging: false

                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onPressed: mouse => {
                            dragging = true;
                            NowPlaying.seekToFraction(mouse.x / progressTrack.width);
                        }
                        onPositionChanged: mouse => {
                            if (dragging)
                                NowPlaying.seekToFraction(mouse.x / progressTrack.width);
                        }
                        onReleased: mouse => {
                            NowPlaying.seekToFraction(mouse.x / progressTrack.width);
                            dragging = false;
                        }
                        onCanceled: dragging = false
                    }
                }

                Text {
                    Layout.preferredWidth: 46
                    text: NowPlaying.length > 0 ? NowPlaying.formatTime(NowPlaying.length) : "0:00"
                    color: Theme.subtext
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
