import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

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
    visible: false
    property int selectedIndex: 0
    readonly property var sessionButtons: [btnReboot, btnPowerOff, btnLogout, btnSleep, btnGif, btnLock]

    function dismiss() {
        visible = false;
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
                root.moveSelection(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.moveSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.moveSelection(-3);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.moveSelection(3);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.activateSelected();
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
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
                    root.dismiss();
                    SessionActions.reboot();
                }
                onEscapePressed: root.dismiss()
                onHoverEntered: root.selectButton(0)
                onHoverExited: if (!btnReboot.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    root.selectedIndex = 0;
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
                    root.dismiss();
                    SessionActions.poweroff();
                }
                onEscapePressed: root.dismiss()
                onHoverEntered: root.selectButton(1)
                onHoverExited: if (!btnPowerOff.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    root.selectedIndex = 1;
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
                    root.dismiss();
                    SessionActions.logout();
                }
                onEscapePressed: root.dismiss()
                onHoverEntered: root.selectButton(2)
                onHoverExited: if (!btnLogout.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    root.selectedIndex = 2;
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
                    root.dismiss();
                    SessionActions.suspend();
                }
                onEscapePressed: root.dismiss()
                onHoverEntered: root.selectButton(3)
                onHoverExited: if (!btnSleep.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    root.selectedIndex = 3;
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
                    root.dismiss();
                }
                onEscapePressed: root.dismiss()
                onHoverEntered: root.selectButton(4)
                onHoverExited: if (!btnGif.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    root.selectedIndex = 4;
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
                    root.dismiss();
                    SessionActions.lock();
                }
                onEscapePressed: root.dismiss()
                onHoverEntered: root.selectButton(5)
                onHoverExited: if (!btnLock.activeFocus)
                    currentAction.text = ""
                onActiveFocusChanged: if (activeFocus) {
                    root.selectedIndex = 5;
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
            root.selectButton(0);
        }
    }

    function toggle() {
        visible = !visible;
    }
}
