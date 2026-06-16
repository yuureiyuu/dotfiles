pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property real uiScale: 1

    spacing: 12 * root.uiScale

    LockResourcesPanel {
        uiScale: root.uiScale
    }

    LockNotificationsPanel {
        uiScale: root.uiScale
    }
}
