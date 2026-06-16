pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool scanning: false
    property var networks: []
    property var ethernetDevices: []
    readonly property var activeNetwork: networks.find(network => network.active) ?? null
    readonly property var connectedEthernet: ethernetDevices.find(device => device.connected) ?? null

    function refresh() {
        statusProc.running = false;
        statusProc.command = ["nmcli", "radio", "wifi"];
        statusProc.running = true;

        listProc.running = false;
        listProc.command = ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "device", "wifi", "list"];
        listProc.running = true;

        ethernetProc.running = false;
        ethernetProc.command = ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"];
        ethernetProc.running = true;
    }

    function setWifiEnabled(enabled) {
        wifiProc.running = false;
        wifiProc.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
        wifiProc.running = true;
    }

    function rescan() {
        scanning = true;
        scanProc.running = false;
        scanProc.command = ["nmcli", "device", "wifi", "list", "--rescan", "yes"];
        scanProc.running = true;
    }

    function connect(network) {
        if (!network?.ssid)
            return;

        connectProc.running = false;
        connectProc.command = ["nmcli", "device", "wifi", "connect", network.ssid];
        connectProc.running = true;
    }

    function connectWithPassword(network, password) {
        if (!network?.ssid)
            return;

        connectProc.running = false;
        connectProc.command = password && password.length ? ["nmcli", "device", "wifi", "connect", network.ssid, "password", password] : ["nmcli", "device", "wifi", "connect", network.ssid];
        connectProc.running = true;
    }

    function disconnect() {
        if (!activeNetwork?.ssid)
            return;

        disconnectProc.running = false;
        disconnectProc.command = ["nmcli", "connection", "down", activeNetwork.ssid];
        disconnectProc.running = true;
    }

    function forget(network) {
        if (!network?.ssid)
            return;

        forgetProc.running = false;
        forgetProc.command = ["nmcli", "connection", "delete", network.ssid];
        forgetProc.running = true;
    }

    function parseEthernet(payload) {
        root.ethernetDevices = payload.trim().split("\n").filter(line => line.length).map(line => {
            const parts = line.split(":");
            return {
                device: parts[0] || "",
                type: parts[1] || "",
                state: parts[2] || "",
                connection: parts[3] || ""
            };
        }).filter(device => device.type === "ethernet").map(device => ({
            device: device.device,
            state: device.state,
            connection: device.connection,
            connected: device.state === "connected"
        }));
    }

    function parseNetworks(payload) {
        const placeholder = "QUICKSHELL_ESCAPED_COLON";
        const escapedColon = new RegExp("\\\\:", "g");
        const placeholderRegex = new RegExp(placeholder, "g");
        const grouped = new Map();

        for (const line of payload.trim().split("\n")) {
            if (!line.length)
                continue;

            const parts = line.replace(escapedColon, placeholder).split(":");
            const network = {
                active: parts[0] === "yes",
                strength: parseInt(parts[1] || "0"),
                frequency: parseInt(parts[2] || "0"),
                ssid: parts[3] || "",
                bssid: (parts[4] || "").replace(placeholderRegex, ":"),
                security: parts[5] || ""
            };

            if (!network.ssid.length)
                continue;

            const current = grouped.get(network.ssid);
            if (!current || network.active || (!current.active && network.strength > current.strength))
                grouped.set(network.ssid, network);
        }

        root.networks = Array.from(grouped.values()).sort((a, b) => {
            if (a.active !== b.active)
                return a.active ? -1 : 1;
            return b.strength - a.strength;
        });
    }

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
        stderr: StdioCollector {}
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: root.parseNetworks(text)
        }
        stderr: StdioCollector {}
    }

    Process {
        id: ethernetProc
        stdout: StdioCollector {
            onStreamFinished: root.parseEthernet(text)
        }
        stderr: StdioCollector {}
    }

    Process {
        id: wifiProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: root.refresh()
    }

    Process {
        id: scanProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            root.scanning = false;
            root.refresh();
        }
    }

    Process {
        id: connectProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: root.refresh()
    }

    Process {
        id: disconnectProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: root.refresh()
    }

    Process {
        id: forgetProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: root.refresh()
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
        stderr: StdioCollector {}
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
