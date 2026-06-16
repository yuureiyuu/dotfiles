pragma Singleton

import QtQml
import Quickshell

Singleton {
    id: root

    property int initialSeconds: 25 * 60
    property int remainingSeconds: 25 * 60
    property bool active: false
    property bool running: false
    readonly property real progress: initialSeconds > 0 ? Math.max(0, Math.min(1, remainingSeconds / initialSeconds)) : 0
    property var recentDurations: [10 * 60, 15 * 60, 30 * 60]

    function format(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const rest = (total % 60).toString().padStart(2, "0");
        if (hours > 0)
            return `${hours}:${minutes.toString().padStart(2, "0")}:${rest}`;
        return `${minutes}:${rest}`;
    }

    function formatFull(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0));
        const hours = Math.floor(total / 3600).toString().padStart(2, "0");
        const minutes = Math.floor((total % 3600) / 60).toString().padStart(2, "0");
        const rest = (total % 60).toString().padStart(2, "0");
        return `${hours}:${minutes}:${rest}`;
    }

    function setMinutes(minutes) {
        const clamped = Math.max(1, Math.min(600, Math.round(Number(minutes) || 25)));
        setSeconds(clamped * 60);
    }

    function setSeconds(seconds) {
        const clamped = Math.max(0, Math.min(99 * 3600 + 59 * 60 + 59, Math.round(Number(seconds) || 0)));
        initialSeconds = clamped;
        remainingSeconds = initialSeconds;
        active = false;
        running = false;
    }

    function setParts(hours, minutes, seconds) {
        const h = Math.max(0, Math.min(99, Math.round(Number(hours) || 0)));
        const m = Math.max(0, Math.min(59, Math.round(Number(minutes) || 0)));
        const s = Math.max(0, Math.min(59, Math.round(Number(seconds) || 0)));
        setSeconds(h * 3600 + m * 60 + s);
    }

    function addRecent(seconds) {
        const value = Math.max(1, Math.round(Number(seconds) || initialSeconds));
        const next = [value].concat(recentDurations.filter(item => item !== value)).slice(0, 3);
        recentDurations = next;
    }

    function applyRecent(seconds) {
        setSeconds(seconds);
    }

    function toggle() {
        if (running) {
            running = false;
            return;
        }

        if (initialSeconds <= 0)
            return;

        if (!active || remainingSeconds <= 0)
            remainingSeconds = initialSeconds;

        if (!active)
            addRecent(initialSeconds);

        active = true;
        running = true;
    }

    function reset() {
        active = false;
        running = false;
        initialSeconds = 0;
        remainingSeconds = 0;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.remainingSeconds <= 1) {
                root.remainingSeconds = 0;
                root.active = false;
                root.running = false;
            } else {
                root.remainingSeconds--;
            }
        }
    }
}
