pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

Scope {
    id: root

    property bool visible: false

    function dismiss() {
        visible = false;
    }

    function toggle() {
        visible = !visible;
    }

    Variants {
        model: Quickshell.screens

        SessionWindow {
            required property ShellScreen modelData

            screen: modelData
        }
    }

    component SessionWindow: PanelWindow {
        id: windowRoot

    visible: root.visible

        // Cover the entire screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"
    property int selectedIndex: 0
    readonly property var sessionButtons: [btnReboot, btnPowerOff, btnLogout, btnSleep, btnGif, btnLock]

    function dismiss() {
        root.dismiss();
    }

    function selectButton(index) {
        if (index < 0 || index >= sessionButtons.length)
            return;

        selectedIndex = index;
        sessionButtons[index].forceActiveFocus();
        currentAction.text = sessionButtons[index].text;
    }

    function moveSelection(delta) {
        const next = (selectedIndex + delta + sessionButtons.length) % sessionButtons.length;
        selectButton(next);
    }

    function activateSelected() {
        sessionButtons[selectedIndex].clicked();
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "transparent"
        focus: root.visible

        Keys.onEscapePressed: root.dismiss()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left) {
                windowRoot.moveSelection(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                windowRoot.moveSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                windowRoot.moveSelection(-3);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                windowRoot.moveSelection(3);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                windowRoot.activateSelected();
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: windowRoot.dismiss()
        }
    }

    Item {
        anchors.centerIn: parent
        width: 380
        height: 350

        Grid {
            id: buttonGrid
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 3
            spacing: 20

            SessionButton {
                id: btnReboot
                text: "Reboot"
                iconGlyph: Icons.rotateCw
                KeyNavigation.right: btnPowerOff
                KeyNavigation.down: btnSleep
                onClicked: {
                    windowRoot.dismiss();
                    SessionActions.reboot();
                }
                onEscapePressed: windowRoot.dismiss()
                onHoverEntered: windowRoot.selectButton(0)
                onHoverExited: if (!btnReboot.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    windowRoot.selectedIndex = 0;
                    currentAction.text = text
                }
            }

            SessionButton {
                id: btnPowerOff
                text: "PowerOff"
                iconGlyph: Icons.power
                KeyNavigation.left: btnReboot
                KeyNavigation.right: btnLogout
                KeyNavigation.down: btnGif
                onClicked: {
                    windowRoot.dismiss();
                    SessionActions.poweroff();
                }
                onEscapePressed: windowRoot.dismiss()
                onHoverEntered: windowRoot.selectButton(1)
                onHoverExited: if (!btnPowerOff.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    windowRoot.selectedIndex = 1;
                    currentAction.text = text
                }
            }

            SessionButton {
                id: btnLogout
                text: "Logout"
                iconGlyph: Icons.logOut
                KeyNavigation.left: btnPowerOff
                KeyNavigation.down: btnLock
                onClicked: {
                    windowRoot.dismiss();
                    SessionActions.logout();
                }
                onEscapePressed: windowRoot.dismiss()
                onHoverEntered: windowRoot.selectButton(2)
                onHoverExited: if (!btnLogout.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    windowRoot.selectedIndex = 2;
                    currentAction.text = text
                }
            }

            SessionButton {
                id: btnSleep
                text: "SleepMode"
                iconGlyph: Icons.moon
                KeyNavigation.up: btnReboot
                KeyNavigation.right: btnGif
                onClicked: {
                    windowRoot.dismiss();
                    SessionActions.suspend();
                }
                onEscapePressed: windowRoot.dismiss()
                onHoverEntered: windowRoot.selectButton(3)
                onHoverExited: if (!btnSleep.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    windowRoot.selectedIndex = 3;
                    currentAction.text = text
                }
            }

            SessionButton {
                id: btnGif
                text: "bye-bye"
                isGif: true
                iconSource: "../../assets/frieren-spining.gif"
                imageScale: 1.23
                KeyNavigation.up: btnPowerOff
                KeyNavigation.left: btnSleep
                KeyNavigation.right: btnLock
                onClicked: {
                    console.log("Ehehehe");
                    windowRoot.dismiss();
                }
                onEscapePressed: windowRoot.dismiss()
                onHoverEntered: windowRoot.selectButton(4)
                onHoverExited: if (!btnGif.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    windowRoot.selectedIndex = 4;
                    currentAction.text = text
                }
            }

            SessionButton {
                id: btnLock
                text: "ScreenLock"
                iconGlyph: Icons.lockKeyhole
                KeyNavigation.up: btnLogout
                KeyNavigation.left: btnGif
                onClicked: {
                    windowRoot.dismiss();
                    SessionActions.lock();
                }
                onEscapePressed: windowRoot.dismiss()
                onHoverEntered: windowRoot.selectButton(5)
                onHoverExited: if (!btnLock.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    windowRoot.selectedIndex = 5;
                    currentAction.text = text
                }
            }
        }

        Text {
            id: currentAction
            anchors.top: buttonGrid.bottom
            anchors.topMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            text: " "
            color: Theme.text
            font.pixelSize: 22
            font.weight: Font.Medium
        }
    }

    onVisibleChanged: {
        if (visible) {
            windowRoot.selectButton(0);
        }
    }
    }
}
