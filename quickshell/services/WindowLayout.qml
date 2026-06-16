pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property list<var> clients: []
    property list<var> workspaces: []
    property list<var> monitors: []
    property var clientByAddress: ({})
    property bool loading: true

    readonly property int activeWorkspaceId: activeWorkspaceProc.workspaceId

    function refresh() {
        if (!clientsProc.running)
            clientsProc.running = true;
        if (!workspacesProc.running)
            workspacesProc.running = true;
        if (!monitorsProc.running)
            monitorsProc.running = true;
        if (!activeWorkspaceProc.running)
            activeWorkspaceProc.running = true;
    }

    function scheduleRefresh() {
        refreshTimer.restart();
    }

    function visibleClients() {
        return clients.filter(client => client.mapped && !client.hidden);
    }

    function workspaceClients(workspaceId) {
        return visibleClients().filter(client => client.workspace?.id === workspaceId);
    }

    function monitorWorkspaces(monitorName) {
        return workspaces.filter(workspace => workspace.monitor === monitorName && workspace.id >= 1 && workspace.id <= 100).sort((a, b) => a.id - b.id);
    }

    function workspaceLabel(workspace) {
        return workspace?.name?.length ? workspace.name : String(workspace?.id ?? "");
    }

    function classLabel(client) {
        return client?.class?.length ? client.class : (client?.initialClass || "application");
    }

    function windowTitle(client) {
        return client?.title?.length ? client.title : classLabel(client);
    }

    function dispatch(request) {
        Hyprland.dispatch(request);
        scheduleRefresh();
    }

    function focusWindow(address) {
        if (address.length)
            dispatch(`hl.dsp.focus({window = "address:${address}"})`);
    }

    function closeWindow(address) {
        if (address.length)
            dispatch(`hl.dsp.window.close({window = "address:${address}"})`);
    }

    function moveToWorkspace(address, workspaceId) {
        if (address.length && workspaceId > 0)
            dispatch(`hl.dsp.window.move({workspace = ${workspaceId}, follow = false, window = "address:${address}"})`);
    }

    function moveToMonitor(address, monitorName) {
        if (address.length && monitorName.length) {
            Quickshell.execDetached(["hyprctl", "dispatch", "movewindow", `mon:${monitorName},address:${address}`]);
            scheduleRefresh();
        }
    }

    function moveDirection(address, direction) {
        if (address.length && direction.length) {
            Quickshell.execDetached(["hyprctl", "dispatch", "movewindoworgroup", `${direction},address:${address}`]);
            scheduleRefresh();
        }
    }

    function toggleFloating(address) {
        if (address.length) {
            Quickshell.execDetached(["hyprctl", "dispatch", "togglefloating", `address:${address}`]);
            scheduleRefresh();
        }
    }

    function focusWorkspace(workspaceId) {
        if (workspaceId > 0)
            dispatch(`hl.dsp.focus({workspace = ${workspaceId}})`);
    }

    function swapWindows(sourceAddress, targetAddress) {
        if (!sourceAddress.length || !targetAddress.length || sourceAddress === targetAddress)
            return;

        const source = clientByAddress[sourceAddress];
        const target = clientByAddress[targetAddress];
        if (!source || !target)
            return;

        if (source.workspace?.id !== target.workspace?.id) {
            moveToWorkspace(sourceAddress, target.workspace.id);
            moveToWorkspace(targetAddress, source.workspace.id);
            scheduleRefresh();
            return;
        }

        Hyprland.dispatch(`hl.dsp.focus({window = "address:${sourceAddress}"})`);
        Quickshell.execDetached(["hyprctl", "dispatch", "swapwindow", `address:${targetAddress}`]);
        scheduleRefresh();
    }

    function parseClients(payload) {
        const next = JSON.parse(payload).filter(client => client.mapped && !client.hidden);
        let byAddress = {};
        for (const client of next)
            byAddress[client.address] = client;

        clients = next;
        clientByAddress = byAddress;
        loading = false;
    }

    function parseWorkspaces(payload) {
        workspaces = JSON.parse(payload).filter(workspace => workspace.id >= 1 && workspace.id <= 100).sort((a, b) => a.id - b.id);
    }

    function parseMonitors(payload) {
        monitors = JSON.parse(payload).filter(monitor => !monitor.disabled);
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshTimer

        interval: 160
        repeat: false
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "openlayer" || event.name === "closelayer")
                return;
            root.scheduleRefresh();
        }
    }

    Process {
        id: clientsProc

        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector

            onStreamFinished: root.parseClients(clientsCollector.text)
        }
    }

    Process {
        id: workspacesProc

        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector

            onStreamFinished: root.parseWorkspaces(workspacesCollector.text)
        }
    }

    Process {
        id: monitorsProc

        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector

            onStreamFinished: root.parseMonitors(monitorsCollector.text)
        }
    }

    Process {
        id: activeWorkspaceProc

        property int workspaceId: 1

        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector

            onStreamFinished: activeWorkspaceProc.workspaceId = JSON.parse(activeWorkspaceCollector.text).id ?? 1
        }
    }
}
