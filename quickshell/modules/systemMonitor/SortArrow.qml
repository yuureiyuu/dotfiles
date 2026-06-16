pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"

LucideIcon {
    id: root

    property bool descending: true
    property color arrowColor: Theme.icon

    implicitWidth: 8
    implicitHeight: 8
    iconSize: Math.max(8, Math.min(width || 8, height || 8) + 3)
    icon: descending ? Icons.chevronDown : Icons.chevronUp
    color: arrowColor
}
