pragma ComponentBehavior: Bound

import QtQml
import "../../services"

QtObject {
    id: root

    property bool active: true
    property bool retained: false

    function syncRetain() {
        if (active && !retained) {
            SystemStats.retain();
            retained = true;
        } else if (!active && retained) {
            SystemStats.release();
            retained = false;
        }
    }

    onActiveChanged: syncRetain()
    Component.onCompleted: syncRetain()
    Component.onDestruction: {
        if (retained)
            SystemStats.release();
    }
}
