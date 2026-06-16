pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../components"
import "../../services"

Scope {
    id: root

    readonly property bool locked: LockState.locked
    readonly property string avatarPath: (Quickshell.env("HOME") || "") + "/.face"
    property date currentDate: new Date()
    property real surfaceWidth: 1366
    property real surfaceHeight: 768
    readonly property real layoutScale: Math.max(0.72, Math.min(1.0, Math.min(surfaceWidth / 1440, surfaceHeight / 960)))
    property string passwordBuffer: ""
    property string statusText: ""
    property bool passwordActive: passwordPam.active
    property int submittedPasswordLength: 0
    readonly property int visiblePasswordLength: Math.max(root.passwordBuffer.length, root.submittedPasswordLength)

    function lock() {
        root.currentDate = new Date();
        LockState.beginLock();
        delayedLockTimer.restart();
    }

    function unlock() {
        root.passwordBuffer = "";
        root.statusText = "";
        root.submittedPasswordLength = 0;
        LockState.unlock();
    }

    onLockedChanged: {
        root.passwordBuffer = "";
        root.statusText = "";
        root.submittedPasswordLength = 0;
        if (locked) {
            root.currentDate = new Date();
            NowPlaying.refresh();
        }
    }

    function submitPassword() {
        if (!root.passwordBuffer.length || passwordPam.active)
            return;

        root.submittedPasswordLength = root.passwordBuffer.length;
        root.statusText = "Checking password...";
        passwordPam.start();
    }

    function handleKey(event) {
        if (!root.locked)
            return;

        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            return;
        }

        if (passwordPam.active) {
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submitPassword();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Backspace) {
            root.passwordBuffer = root.passwordBuffer.slice(0, -1);
            root.submittedPasswordLength = 0;
            root.statusText = "";
            event.accepted = true;
            return;
        }

        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) {
            root.passwordBuffer = "";
            root.submittedPasswordLength = 0;
            root.statusText = "";
            event.accepted = true;
            return;
        }

        if (event.text && event.text.length && event.text >= " ") {
            root.passwordBuffer += event.text;
            root.submittedPasswordLength = 0;
            root.statusText = "";
            event.accepted = true;
        }
    }

    PamContext {
        id: passwordPam

        config: "passwd"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;

            respond(root.passwordBuffer);
            root.passwordBuffer = "";
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlock();
                return;
            }

            root.submittedPasswordLength = 0;
            if (result === PamResult.MaxTries)
                root.statusText = "Too many attempts";
            else if (message && message.length)
                root.statusText = message;
            else
                root.statusText = "Wrong password";
        }
    }

    GlobalShortcut {
        name: "lockScreen"
        description: "Locks the current session"
        onPressed: root.lock()
    }

    IpcHandler {
        target: "lock"

        function activate(): void {
            root.lock();
        }

        function deactivate(): void {
            root.unlock();
        }

        function isLocked(): bool {
            return LockState.locked;
        }
    }

    Timer {
        id: delayedLockTimer
        interval: 300
        repeat: false
        onTriggered: LockState.finishLock()
    }

    WlSessionLock {
        id: sessionLock
        locked: LockState.locked

        WlSessionLockSurface {
            id: sessionLockSurface
            color: "transparent"

            onWidthChanged: root.surfaceWidth = width > 0 ? width : 1366
            onHeightChanged: root.surfaceHeight = height > 0 ? height : 768

            Rectangle {
                anchors.fill: parent
                color: Theme.mantle
            }

            ScreencopyView {
                id: workspaceBackground
                anchors.fill: parent
                captureSource: sessionLockSurface.screen
                visible: wallpaperBackground.status !== Image.Ready
            }

            Image {
                id: wallpaperBackground
                anchors.fill: parent
                source: Theme.currentWallpaper
                sourceSize.width: sessionLockSurface.width
                sourceSize.height: sessionLockSurface.height
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                cache: true
                visible: wallpaperBackground.status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.02, 0.025, 0.04, 0.34)
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(0, 0, 0, 0.36)
                    }
                    GradientStop {
                        position: 0.48
                        color: Qt.rgba(0, 0, 0, 0.08)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(0, 0, 0, 0.46)
                    }
                }
            }

            Item {
                id: focusCatcher
                anchors.fill: parent
                focus: root.locked

                Keys.onPressed: event => root.handleKey(event)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onClicked: focusCatcher.forceActiveFocus()
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 34 * root.layoutScale

                    Rectangle {
                        Layout.preferredWidth: 226 * root.layoutScale
                        Layout.preferredHeight: 62 * root.layoutScale
                        radius: 4
                        color: Qt.alpha(Theme.base, 0.76)
                        border.width: 1
                        border.color: Qt.alpha(Theme.text, 0.14)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15 * root.layoutScale
                            anchors.rightMargin: 15 * root.layoutScale
                            spacing: 10 * root.layoutScale

                            ThemedSvgIcon {
                                Layout.preferredWidth: 22 * root.layoutScale
                                Layout.preferredHeight: 22 * root.layoutScale
                                iconName: "lock-keyhole"
                                iconSize: 22 * root.layoutScale
                                color: Theme.accent
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: SystemStats.username || "locked"
                                    color: Theme.text
                                    font.pixelSize: 14 * root.layoutScale
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: SystemStats.hostname || "session locked"
                                    color: Qt.alpha(Theme.text, 0.56)
                                    font.pixelSize: 11 * root.layoutScale
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                LockWeatherWidget {
                    visible: SettingsService.weatherService
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 34 * root.layoutScale
                    width: Math.max(320 * root.layoutScale, Math.min(parent.width - 520 * root.layoutScale, 480 * root.layoutScale))
                    height: 78 * root.layoutScale
                    uiScale: root.layoutScale
                    blurSource: wallpaperBackground
                }

                LockPaletteStrip {
                    anchors.left: parent.left
                    anchors.leftMargin: 34 * root.layoutScale
                    anchors.verticalCenter: parent.verticalCenter
                    uiScale: root.layoutScale
                }

                LockAuthPanel {
                    id: authPanel
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -30 * root.layoutScale
                    width: Math.min(parent.width - 70 * root.layoutScale, 540 * root.layoutScale)
                    height: Math.min(parent.height - 250 * root.layoutScale, 520 * root.layoutScale)
                    uiScale: root.layoutScale
                    currentDate: root.currentDate
                    avatarPath: root.avatarPath
                    visiblePasswordLength: root.visiblePasswordLength
                    passwordActive: root.passwordActive
                    passwordBufferLength: root.passwordBuffer.length
                    statusText: root.statusText
                    onSubmitRequested: {
                        focusCatcher.forceActiveFocus();
                        root.submitPassword();
                    }
                }

                LockMediaPlayer {
                    visible: SettingsService.nowPlayingService
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 30 * root.layoutScale
                    width: Math.min(parent.width - 560 * root.layoutScale, 760 * root.layoutScale)
                    height: 188 * root.layoutScale
                    uiScale: root.layoutScale
                }

                LockNotificationsHistory {
                    visible: SettingsService.showNotifications
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 34 * root.layoutScale
                    anchors.topMargin: 34 * root.layoutScale
                    width: 440 * root.layoutScale
                    height: Math.min(parent.height - 90 * root.layoutScale, 560 * root.layoutScale)
                    uiScale: root.layoutScale
                    blurSource: wallpaperBackground
                }

                Timer {
                    id: clockTimer
                    interval: 1000
                    running: root.locked
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: root.currentDate = new Date()
                }

                Component.onCompleted: focusCatcher.forceActiveFocus()
            }
        }
    }
}
