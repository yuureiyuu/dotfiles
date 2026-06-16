pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    property var popupItems: ({})
    readonly property int popupSpacing: 10

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    visible: SettingsService.showNotifications && Notifications.popups.length > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    anchors {
        top: true
        left: true
    }

    implicitWidth: 376
    implicitHeight: popupStack.contentHeight + 16
    mask: Region {
        item: popupStack
    }

    function reconcilePopups() {
        const activeIds = {};

        for (const entry of Notifications.popups) {
            activeIds[entry.entryUid] = true;

            if (popupItems[entry.entryUid])
                continue;

            const item = popupComponent.createObject(popupStack, {
                entry: entry,
                width: popupStack.width
            });

            if (!item)
                continue;

            item.implicitHeightChanged.connect(layoutPopups);
            popupItems[entry.entryUid] = item;
        }

        for (const entryUid in popupItems) {
            if (activeIds[entryUid])
                continue;

            popupItems[entryUid].destroy();
            delete popupItems[entryUid];
        }

        layoutPopups();
    }

    function layoutPopups() {
        let nextY = 0;

        for (const entry of Notifications.popups) {
            const item = popupItems[entry.entryUid];
            if (!item)
                continue;

            item.width = popupStack.width;
            item.y = nextY;
            nextY += item.implicitHeight + root.popupSpacing;
        }

        popupStack.contentHeight = Math.max(0, nextY - root.popupSpacing);
    }

    Component.onCompleted: reconcilePopups()

    Connections {
        target: Notifications

        function onPopupsChanged() {
            root.reconcilePopups();
        }
    }

    Item {
        id: popupStack

        property real contentHeight: 0

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 8
        anchors.topMargin: 8
        width: 360
        height: contentHeight
    }

    Component {
        id: popupComponent

        NotificationPopup {}
    }
}
