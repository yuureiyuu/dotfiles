pragma Singleton
pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<QtObject> list: []
    readonly property list<QtObject> popups: list.filter(entry => entry.popup)
    readonly property int unreadCount: list.length
    readonly property int maxHistory: 40
    readonly property int popupTimeout: 5000
    readonly property int popupExitDuration: 220
    property int nextEntryUid: 0

    function removeEntry(entry, dismissNotification) {
        if (!entry)
            return;

        root.list = root.list.filter(item => item !== entry);

        if (dismissNotification)
            entry.notification?.dismiss();

        entry.destroy();
    }

    function clear() {
        for (const entry of root.list.slice())
            root.removeEntry(entry, true);
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const existingEntry = notification.id ? root.list.find(entry => entry.notificationId === notification.id) : null;
            if (existingEntry)
                root.removeEntry(existingEntry, false);

            const entry = entryComponent.createObject(root, {
                notification: notification,
                entryUid: `notification-${++root.nextEntryUid}`,
                notificationId: notification.id,
                appName: notification.appName || "Notification",
                appIcon: notification.appIcon || "",
                summary: notification.summary || "",
                body: notification.body || "",
                image: notification.image || "",
                expireTimeout: notification.expireTimeout || root.popupTimeout,
                urgency: notification.urgency,
                resident: notification.resident,
                hasActionIcons: notification.hasActionIcons,
                actions: notification.actions.map(action => ({
                    identifier: action.identifier,
                    text: action.text,
                    invoke: () => action.invoke()
                })),
                time: new Date()
            });

            const nextList = [entry, ...root.list];
            const overflow = nextList.slice(root.maxHistory);
            root.list = nextList.slice(0, root.maxHistory);
            for (const oldEntry of overflow)
                oldEntry.destroy();

            entry.startPopupTimeout();
        }
    }

    Component {
        id: entryComponent

        NotificationEntry {}
    }

    component NotificationEntry: QtObject {
        id: entry

        property var notification
        property string entryUid: ""
        property int notificationId: 0
        property string appName: ""
        property string appIcon: ""
        property string summary: ""
        property string body: ""
        property string image: ""
        property int expireTimeout: root.popupTimeout
        property int urgency: NotificationUrgency.Normal
        property bool resident: false
        property bool hasActionIcons: false
        property var actions: []
        property date time: new Date()
        property bool popup: true
        property bool popupClosing: false
        property bool popupEntered: false

        readonly property Connections notificationConnections: Connections {
            target: entry.notification

            function onClosed() {
                root.removeEntry(entry, false);
            }

            function onAppNameChanged() {
                entry.appName = entry.notification.appName || "Notification";
            }

            function onAppIconChanged() {
                entry.appIcon = entry.notification.appIcon || "";
            }

            function onSummaryChanged() {
                entry.summary = entry.notification.summary || "";
            }

            function onBodyChanged() {
                entry.body = entry.notification.body || "";
            }

            function onImageChanged() {
                entry.image = entry.notification.image || "";
            }

            function onExpireTimeoutChanged() {
                entry.expireTimeout = entry.notification.expireTimeout || root.popupTimeout;
            }

            function onUrgencyChanged() {
                entry.urgency = entry.notification.urgency;
            }

            function onResidentChanged() {
                entry.resident = entry.notification.resident;
            }

            function onHasActionIconsChanged() {
                entry.hasActionIcons = entry.notification.hasActionIcons;
            }

            function onActionsChanged() {
                entry.actions = entry.notification.actions.map(action => ({
                    identifier: action.identifier,
                    text: action.text,
                    invoke: () => action.invoke()
                }));
            }
        }

        readonly property Timer popupTimer: Timer {
            interval: root.popupTimeout
            repeat: false
            onTriggered: entry.dismissPopup()
        }

        readonly property Timer popupDestroyTimer: Timer {
            interval: root.popupExitDuration
            repeat: false
            onTriggered: entry.popup = false
        }

        function startPopupTimeout() {
            popup = true;
            popupClosing = false;
            popupTimer.restart();
        }

        function dismissPopup() {
            if (!popup || popupClosing)
                return;

            popupClosing = true;
            popupTimer.stop();
            popupDestroyTimer.restart();
        }

        function close() {
            root.removeEntry(entry, true);
        }
    }
}
