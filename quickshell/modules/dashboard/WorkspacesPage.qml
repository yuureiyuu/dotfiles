pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../services"

Item {
    id: root

    readonly property int columns: 5
    readonly property int rows: 2
    readonly property int workspaceCount: columns * rows
    readonly property int activeWorkspaceId: WindowLayout.activeWorkspaceId
    readonly property int workspaceGroup: Math.floor((Math.max(1, activeWorkspaceId) - 1) / workspaceCount)
    readonly property real tileGap: 5
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property string draggingAddress: ""
    property string draggingTargetAddress: ""

    function workspaceAt(index) {
        return workspaceGroup * workspaceCount + index + 1;
    }

    function workspaceAtCell(row, column) {
        return workspaceGroup * workspaceCount + row * columns + column + 1;
    }

    function clientsForWorkspace(workspaceId) {
        return WindowLayout.workspaceClients(workspaceId);
    }

    function monitorForClient(client) {
        return WindowLayout.monitors.find(monitor => monitor.id === client?.monitor) ?? WindowLayout.monitors[0] ?? null;
    }

    function usableRect(monitor) {
        if (!monitor)
            return {
                "x": 0,
                "y": 0,
                "width": 1,
                "height": 1
            };

        const reserved = monitor.reserved ?? [0, 0, 0, 0];
        const rotated = monitor.transform % 2 === 1;
        return {
            "x": monitor.x + reserved[0],
            "y": monitor.y + reserved[1],
            "width": Math.max(1, (rotated ? monitor.height : monitor.width) - reserved[0] - reserved[2]),
            "height": Math.max(1, (rotated ? monitor.width : monitor.height) - reserved[1] - reserved[3])
        };
    }

    function toplevelFor(address) {
        const values = ToplevelManager.toplevels?.values ?? [];
        return values.find(toplevel => `0x${toplevel.HyprlandToplevel?.address}` === address) ?? null;
    }

    DashboardPanel {
        anchors.fill: parent
        clip: true

        Item {
            id: overview

            anchors.fill: parent
            anchors.margins: 14
            clip: true

            readonly property real tileWidth: Math.floor((width - root.tileGap * (root.columns - 1)) / root.columns)
            readonly property real tileHeight: Math.floor((height - root.tileGap * (root.rows - 1)) / root.rows)

            Repeater {
                model: root.workspaceCount

                WorkspaceTile {
                    required property int index

                    workspaceId: root.workspaceAt(index)
                    x: (index % root.columns) * (overview.tileWidth + root.tileGap)
                    y: Math.floor(index / root.columns) * (overview.tileHeight + root.tileGap)
                    width: overview.tileWidth
                    height: overview.tileHeight
                }
            }
        }
    }

    component WorkspaceTile: Rectangle {
        id: tile

        required property int workspaceId
        readonly property var clients: root.clientsForWorkspace(workspaceId)
        readonly property bool active: workspaceId === root.activeWorkspaceId
        readonly property bool dropActive: root.draggingTargetWorkspace === workspaceId

        radius: 7
        color: dropActive ? Qt.alpha(Theme.accent, 0.22) : Qt.alpha(Theme.surface, active ? 0.62 : 0.42)
        border.width: active || dropActive ? 2 : 1
        border.color: dropActive ? Qt.alpha(Theme.accent2, 0.88) : (active ? Qt.alpha(Theme.text, 0.70) : Qt.alpha(Theme.text, 0.08))
        clip: true

        Behavior on border.color {
            ColorAnimation {
                duration: 140
            }
        }

        Text {
            anchors.centerIn: parent
            text: tile.workspaceId
            color: Qt.alpha(Theme.text, tile.clients.length ? 0.13 : 0.28)
            font.pixelSize: Math.min(tile.width, tile.height) * 0.38
            font.weight: Font.DemiBold
        }

        Flow {
            anchors {
                left: parent.left
                top: parent.top
                margins: 7
            }
            spacing: 4
            visible: tile.clients.length > 0
            z: 5

            Repeater {
                model: tile.clients.slice(0, 4)

                Rectangle {
                    required property var modelData

                    width: 20
                    height: 20
                    radius: 4
                    color: Qt.alpha(Theme.mantle, 0.72)
                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.12)

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: Quickshell.iconPath(WindowLayout.classLabel(modelData), "application-x-executable")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            z: 0
            onClicked: WindowLayout.focusWorkspace(tile.workspaceId)
        }

        Repeater {
            model: tile.clients

            WindowPreview {
                required property var modelData

                client: modelData
                tileWidth: tile.width
                tileHeight: tile.height
            }
        }

        DropArea {
            anchors.fill: parent
            keys: ["workspace-window"]
            z: 30
            onEntered: root.draggingTargetWorkspace = tile.workspaceId
            onExited: if (root.draggingTargetWorkspace === tile.workspaceId)
                root.draggingTargetWorkspace = -1
            onDropped: {
                if (root.draggingTargetAddress.length) {
                    WindowLayout.swapWindows(root.draggingAddress, root.draggingTargetAddress);
                } else if (root.draggingAddress.length && root.draggingFromWorkspace !== tile.workspaceId) {
                    WindowLayout.moveToWorkspace(root.draggingAddress, tile.workspaceId);
                }
                root.draggingTargetWorkspace = -1;
                root.draggingTargetAddress = "";
                root.draggingAddress = "";
                root.draggingFromWorkspace = -1;
            }
        }
    }

    component WindowPreview: Item {
        id: preview

        required property var client
        required property real tileWidth
        required property real tileHeight
        readonly property string address: client.address ?? ""
        readonly property var monitor: root.monitorForClient(client)
        readonly property var usable: root.usableRect(monitor)
        readonly property var toplevel: root.toplevelFor(address)
        readonly property real scaleX: tileWidth / usable.width
        readonly property real scaleY: tileHeight / usable.height
        readonly property real naturalX: Math.max(4, (client.at[0] - usable.x) * scaleX)
        readonly property real naturalY: Math.max(4, (client.at[1] - usable.y) * scaleY)
        readonly property real naturalWidth: Math.max(42, client.size[0] * scaleX)
        readonly property real naturalHeight: Math.max(30, client.size[1] * scaleY)
        readonly property real settledWidth: Math.min(tileWidth - 8, naturalWidth)
        readonly property real settledHeight: Math.min(tileHeight - 8, naturalHeight)
        readonly property real settledX: Math.min(tileWidth - settledWidth - 4, naturalX)
        readonly property real settledY: Math.min(tileHeight - settledHeight - 4, naturalY)
        property bool hovered: false
        property bool pressed: false

        x: settledX
        y: settledY
        width: settledWidth
        height: settledHeight
        z: Drag.active ? 99 : (client.floating ? 8 : 4)
        opacity: client.monitor === (WindowLayout.monitors[0]?.id ?? client.monitor) ? 1 : 0.55

        Drag.active: dragArea.drag.active
        Drag.keys: ["workspace-window"]
        Drag.source: preview
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Behavior on x {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: Qt.alpha(Theme.mantle, preview.pressed ? 0.62 : (preview.hovered ? 0.42 : 0.24))
            border.width: 1
            border.color: root.draggingTargetAddress === preview.address ? Qt.alpha(Theme.accent2, 0.92) : Qt.alpha(Theme.text, 0.16)
        }

        ScreencopyView {
            anchors.fill: parent
            captureSource: preview.toplevel
            live: true
            visible: preview.toplevel !== null

            Rectangle {
                anchors.fill: parent
                radius: 5
                color: Qt.alpha(Theme.mantle, preview.hovered ? 0.18 : 0.04)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.10)
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.34
            height: width
            radius: 6
            color: Qt.alpha(Theme.mantle, 0.72)
            visible: preview.toplevel === null || parent.width < 82 || parent.height < 54

            Image {
                anchors.centerIn: parent
                width: parent.width * 0.62
                height: width
                source: Quickshell.iconPath(WindowLayout.classLabel(preview.client), "application-x-executable")
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        Rectangle {
            anchors {
                right: parent.right
                top: parent.top
                margins: 4
            }
            width: 20
            height: 20
            radius: 4
            color: closeMouse.containsMouse ? Qt.alpha("#ff6b6b", 0.46) : Qt.alpha(Theme.mantle, 0.66)
            border.width: 1
            border.color: Qt.alpha("#ffaaaa", closeMouse.containsMouse ? 0.72 : 0.20)
            visible: preview.hovered || closeMouse.containsMouse
            z: 20

            ThemedSvgIcon {
                anchors.centerIn: parent
                iconName: "x"
                iconSize: 12
                color: "#ffdddd"
            }

            MouseArea {
                id: closeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    WindowLayout.closeWindow(preview.address);
                    mouse.accepted = true;
                }
            }
        }

        MouseArea {
            id: dragArea

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            hoverEnabled: true
            drag.target: preview
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            onEntered: preview.hovered = true
            onExited: preview.hovered = false
            onPressed: mouse => {
                root.draggingFromWorkspace = preview.client.workspace?.id ?? -1;
                root.draggingAddress = preview.address;
                root.draggingTargetAddress = "";
                preview.pressed = true;
                preview.Drag.hotSpot.x = mouse.x;
                preview.Drag.hotSpot.y = mouse.y;
            }
            onReleased: mouse => {
                const targetWorkspace = root.draggingTargetWorkspace;
                const targetAddress = root.draggingTargetAddress;
                preview.pressed = false;
                preview.x = preview.settledX;
                preview.y = preview.settledY;

                if (mouse.button === Qt.MiddleButton) {
                    WindowLayout.closeWindow(preview.address);
                } else if (targetAddress.length && targetAddress !== preview.address) {
                    WindowLayout.swapWindows(preview.address, targetAddress);
                } else if (targetWorkspace > 0 && targetWorkspace !== preview.client.workspace?.id) {
                    WindowLayout.moveToWorkspace(preview.address, targetWorkspace);
                }

                root.draggingFromWorkspace = -1;
                root.draggingTargetWorkspace = -1;
                root.draggingTargetAddress = "";
                root.draggingAddress = "";
            }
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    WindowLayout.focusWindow(preview.address);
            }
        }

        DropArea {
            anchors.fill: parent
            keys: ["workspace-window"]
            onEntered: if (root.draggingAddress !== preview.address)
                root.draggingTargetAddress = preview.address
            onExited: if (root.draggingTargetAddress === preview.address)
                root.draggingTargetAddress = ""
        }
    }
}
