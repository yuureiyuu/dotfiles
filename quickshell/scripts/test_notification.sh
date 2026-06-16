#!/usr/bin/env bash
set -euo pipefail

summary="${1:-Quickshell notification test}"
body="${2:-If this popup appears in the top-left corner, the notification service is working.}"
app_name="Quickshell test"
app_icon="dialog-information"
expire_timeout=3000

if command -v busctl >/dev/null 2>&1; then
    busctl --user call \
        org.freedesktop.Notifications \
        /org/freedesktop/Notifications \
        org.freedesktop.Notifications \
        Notify \
        susssasa{sv}i \
        "$app_name" \
        0 \
        "$app_icon" \
        "$summary" \
        "$body" \
        0 \
        0 \
        "$expire_timeout" >/dev/null
    exit 0
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="$app_name" --icon="$app_icon" --expire-time="$expire_timeout" "$summary" "$body"
    exit 0
fi

printf 'No supported notification sender found. Install libnotify or systemd busctl.\n' >&2
exit 1
