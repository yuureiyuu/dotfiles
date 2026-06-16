pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import "../../services"

Item {
    id: root

    property bool horizontal: false
    width: 59
    height: horizontal ? 42 : 166
    clip: true
    visible: activeWorkspaceId >= 1 && activeWorkspaceId <= 10

    readonly property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    property int previousWorkspaceId: activeWorkspaceId
    property string shownLabel: workspaceName(activeWorkspaceId)
    property string incomingLabel: shownLabel
    property int swipeDirection: 1

    function workspaceName(id) {
        const names = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"];
        return id >= 1 && id <= 10 ? names[id] : "";
    }

    function channel(hex, index) {
        return parseInt(hex.slice(index, index + 2), 16) / 255;
    }

    function luminance(hex) {
        const value = hex.length === 9 ? hex.slice(0, 7) : hex;
        const components = [channel(value, 1), channel(value, 3), channel(value, 5)].map(component => {
            return component <= 0.03928 ? component / 12.92 : Math.pow((component + 0.055) / 1.055, 2.4);
        });
        return 0.2126 * components[0] + 0.7152 * components[1] + 0.0722 * components[2];
    }

    function contrast(a, b) {
        const first = luminance(a);
        const second = luminance(b);
        const light = Math.max(first, second);
        const dark = Math.min(first, second);
        return (light + 0.05) / (dark + 0.05);
    }

    function workspaceColor() {
        const candidates = [
            Theme.accentHex,
            Theme.accent2Hex,
            Theme.textHex,
            Theme.swatch0,
            Theme.swatch1,
            Theme.swatch2,
            Theme.swatch3
        ];
        let best = Theme.textHex;
        let bestScore = 0;

        for (const color of candidates) {
            const score = contrast(color, Theme.mantleHex);
            if (score > bestScore) {
                best = color;
                bestScore = score;
            }
        }

        return bestScore >= 4.5 ? best : Theme.textHex;
    }

    function animateToWorkspace(id) {
        const nextLabel = workspaceName(id);
        if (!nextLabel || nextLabel === shownLabel)
            return;

        workspaceAnimation.stop();
        swipeDirection = id > previousWorkspaceId ? 1 : -1;
        incomingLabel = nextLabel;
        currentText.y = 0;
        currentText.opacity = 1;
        nextText.y = root.height * swipeDirection;
        nextText.opacity = 0;
        workspaceAnimation.start();
    }

    onActiveWorkspaceIdChanged: {
        animateToWorkspace(activeWorkspaceId);
        previousWorkspaceId = activeWorkspaceId;
    }

    component VerticalWorkspaceLabel: Item {
        id: labelRoot

        property string label: ""

        width: root.width
        height: root.height

        Column {
            visible: !root.horizontal
            anchors.centerIn: parent
            spacing: -2

            Repeater {
                model: labelRoot.label.split("")

                Text {
                    required property string modelData

                    width: labelRoot.width
                    text: modelData
                    color: root.workspaceColor()
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Sawarabi Gothic"
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0
                }
            }
        }

        Text {
            visible: root.horizontal
            anchors.centerIn: parent
            text: labelRoot.label
            color: root.workspaceColor()
            horizontalAlignment: Text.AlignHCenter
            font.family: "Sawarabi Gothic"
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }
    }

    VerticalWorkspaceLabel {
        id: currentText

        label: root.shownLabel
    }

    VerticalWorkspaceLabel {
        id: nextText

        label: root.incomingLabel
        opacity: 0
    }

    ParallelAnimation {
        id: workspaceAnimation

        NumberAnimation {
            target: currentText
            property: "y"
            to: -root.height * root.swipeDirection
            duration: 260
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: currentText
            property: "opacity"
            to: 0
            duration: 170
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: nextText
            property: "y"
            to: 0
            duration: 260
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: nextText
            property: "opacity"
            to: 1
            duration: 190
            easing.type: Easing.OutQuad
        }

        onFinished: {
            root.shownLabel = root.incomingLabel;
            currentText.y = 0;
            currentText.opacity = 1;
            nextText.y = 0;
            nextText.opacity = 0;
        }
    }

    Connections {
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "workspacev2" || event.name === "focusedmon")
                Hyprland.refreshWorkspaces();
        }

        target: Hyprland
    }
}
