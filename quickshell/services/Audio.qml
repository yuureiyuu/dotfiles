pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Hyprland

Singleton {
    id: root

    property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property list<var> appStreams: Pipewire.nodes.values.filter(node => node.isStream && node.isSink && node.audio)
    readonly property list<var> outputDevices: Pipewire.nodes.values.filter(node => !node.isStream && node.isSink && node.audio)
    signal outputChangedByUser

    function displayName(node) {
        return node?.properties?.["application.name"] || node?.description || node?.name || "Application";
    }

    function volumeIcon(value, muted) {
        if (muted || value <= 0.005)
            return "volume";
        if (value <= 0.40)
            return "volume-1";
        return "volume-2";
    }

    function setVolume(value) {
        if (!sink?.audio)
            return;

        sink.audio.volume = Math.max(0, Math.min(1.5, value));
        outputChangedByUser();
    }

    function setMuted(value) {
        if (sink?.audio) {
            sink.audio.muted = value;
            outputChangedByUser();
        }
    }

    function increaseVolume() {
        setVolume(volume + 0.05);
    }

    function decreaseVolume() {
        setVolume(volume - 0.05);
    }

    function setStreamVolume(node, value) {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1.5, value));
    }

    function setStreamMuted(node, value) {
        if (node?.audio)
            node.audio.muted = value;
    }

    function setDefaultSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    PwObjectTracker {
        objects: [root.sink, ...root.outputDevices, ...root.appStreams]
    }
}
