pragma Singleton

import Quickshell
import "."

Singleton {
    function lock() {
        Quickshell.execDetached([
            "bash",
            "-lc",
            "qs ipc call lock activate >/dev/null 2>&1 || quickshell ipc call lock activate >/dev/null 2>&1"
        ]);
    }

    function suspend() {
        Quickshell.execDetached([
            "bash",
            "-lc",
            "systemctl suspend || loginctl suspend"
        ]);
    }

    function logout() {
        Quickshell.execDetached([
            "bash",
            "-lc",
            "hyprctl dispatch exit || loginctl terminate-session \"$XDG_SESSION_ID\""
        ]);
    }

    function poweroff() {
        Quickshell.execDetached([
            "bash",
            "-lc",
            "systemctl poweroff || poweroff || loginctl poweroff"
        ]);
    }

    function reboot() {
        Quickshell.execDetached([
            "bash",
            "-lc",
            "systemctl reboot || reboot || loginctl reboot"
        ]);
    }
}
