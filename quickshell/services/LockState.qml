pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool pendingLock: false
    property bool locked: false

    function beginLock() {
        root.pendingLock = true;
    }

    function finishLock() {
        root.pendingLock = false;
        root.locked = true;
    }

    function unlock() {
        root.pendingLock = false;
        root.locked = false;
    }
}
