pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../services"
import "../../components"

Item {
    id: root

    property bool active: false
    property string processQuery: ""
    property var filteredProcesses: []
    property var selectedProcess: null
    property string sortKey: "cpu"
    property bool sortDescending: true
    readonly property int filteredCount: filteredProcesses.length

    signal requestStatistics

    function sortValue(process, key) {
        if (key === "name")
            return (process.name || "").toLowerCase();
        if (key === "cpu")
            return process.cpu || 0;
        if (key === "memory")
            return process.memory || 0;
        if (key === "rss")
            return process.rssMiB || 0;
        if (key === "gpu")
            return process.gpuMemoryMiB || 0;
        return process.cpu || 0;
    }

    function sortedProcesses(processes) {
        return processes.slice().sort((a, b) => {
            const left = root.sortValue(a, root.sortKey);
            const right = root.sortValue(b, root.sortKey);
            let result = 0;

            if (typeof left === "string" || typeof right === "string")
                result = String(left).localeCompare(String(right));
            else
                result = left - right;

            if (result === 0)
                result = Number(a.pid || 0) - Number(b.pid || 0);

            return root.sortDescending ? -result : result;
        });
    }

    function setSort(key) {
        if (!key.length)
            return;

        if (root.sortKey === key)
            root.sortDescending = !root.sortDescending;
        else {
            root.sortKey = key;
            root.sortDescending = key !== "name";
        }
    }

    function refreshFilteredProcesses(preserveView) {
        const previousContentY = preserveView ? processList.contentY : 0;
        const previousPid = root.selectedProcess ? root.selectedProcess.pid : "";
        const query = root.processQuery.trim().toLowerCase();
        const source = SystemStats.processes || [];
        let filtered = source;

        if (!query.length) {
            filtered = source;
        } else {
            filtered = source.filter(process => {
                const haystack = `${process.pid} ${process.ppid} ${process.name} ${process.state} ${process.command}`.toLowerCase();
                return haystack.indexOf(query) >= 0;
            });
        }

        root.filteredProcesses = root.sortedProcesses(filtered);

        if (previousPid.length && root.filteredProcesses.some(process => process.pid === previousPid))
            root.selectedProcess = root.filteredProcesses.find(process => process.pid === previousPid);
        else if (!root.selectedProcess && root.filteredProcesses.length > 0)
            root.selectedProcess = root.filteredProcesses[0];
        else if (root.selectedProcess && !root.filteredProcesses.some(process => process.pid === root.selectedProcess.pid))
            root.selectedProcess = root.filteredProcesses.length > 0 ? root.filteredProcesses[0] : null;

        processList.currentIndex = root.selectedProcess ? Math.max(0, root.filteredProcesses.findIndex(process => process.pid === root.selectedProcess.pid)) : -1;

        if (preserveView) {
            Qt.callLater(() => {
                processList.contentY = Math.max(processList.originY, Math.min(previousContentY, processList.contentHeight - processList.height));
            });
        } else {
            processList.contentY = processList.originY;
        }
    }

    function selectProcess(index) {
        if (!root.filteredProcesses.length) {
            root.selectedProcess = null;
            processList.currentIndex = -1;
            return;
        }

        const nextIndex = Math.max(0, Math.min(root.filteredProcesses.length - 1, index));
        processList.currentIndex = nextIndex;
        root.selectedProcess = root.filteredProcesses[nextIndex];
        processList.positionViewAtIndex(nextIndex, ListView.Contain);
    }

    function moveProcessSelection(delta) {
        const current = processList.currentIndex >= 0 ? processList.currentIndex : 0;
        root.selectProcess(current + delta);
    }

    function focusList() {
        processList.forceActiveFocus();
    }

    function focusSearch() {
        searchField.forceActiveFocus();
        searchField.selectAll();
    }

    onProcessQueryChanged: refreshFilteredProcesses()
    onSortKeyChanged: refreshFilteredProcesses()
    onSortDescendingChanged: refreshFilteredProcesses()
    onActiveChanged: {
        if (active)
            focusList();
    }

    Connections {
        target: SystemStats

        function onProcessesChanged() {
            root.refreshFilteredProcesses(true);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 4
                color: Qt.alpha(Theme.surface, 0.72)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 10

                    LucideIcon {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        icon: Icons.search
                        iconSize: 18
                        color: Theme.iconMuted
                    }

                    TextField {
                        id: searchField

                        Layout.fillWidth: true
                        color: Theme.text
                        placeholderText: "Search by PID, name, state, or command"
                        placeholderTextColor: Theme.subtext
                        background: Item {}
                        selectByMouse: true
                        text: root.processQuery

                        onTextChanged: root.processQuery = text
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                if (text.length > 0)
                                    clear();
                                else
                                    root.focusList();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.moveProcessSelection(1);
                                root.focusList();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.moveProcessSelection(-1);
                                root.focusList();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.focusList();
                                event.accepted = true;
                            }
                        }
                    }

                    Rectangle {
                        visible: searchField.text.length > 0
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 4
                        color: clearSearchArea.containsMouse ? Theme.surface2 : "transparent"

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: Icons.circleX
                            iconSize: 15
                            color: Theme.icon
                        }

                        MouseArea {
                            id: clearSearchArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: searchField.clear()
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 168
                Layout.preferredHeight: 48
                radius: 4
                color: Qt.alpha(Theme.surface, 0.72)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: `${root.filteredProcesses.length} / ${SystemStats.processCount}`
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 4
                color: Qt.alpha(Theme.surface, 0.72)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Qt.alpha(Theme.text, 0.045)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Repeater {
                                model: [["PID", 56, false, ""], ["Process", -1, false, "name"], ["CPU", 64, true, "cpu"], ["RAM", 64, true, "memory"], ["RSS", 72, true, "rss"], ["GPU", 70, true, "gpu"], ["", 34, false, ""]]

                                Item {
                                    required property var modelData

                                    Layout.preferredWidth: modelData[1] > 0 ? modelData[1] : -1
                                    Layout.fillWidth: modelData[1] < 0
                                    Layout.fillHeight: true

                                    Item {
                                        id: headerContent

                                        width: Math.min(parent.width, headerText.implicitWidth + (sortArrow.visible ? sortArrow.width + 5 : 0))
                                        height: parent.height
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: modelData[2] ? undefined : parent.left
                                        anchors.right: modelData[2] ? parent.right : undefined

                                        Text {
                                            id: headerText

                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            text: modelData[0]
                                            color: modelData[3] === root.sortKey ? Theme.text : Theme.subtext
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        SortArrow {
                                            id: sortArrow

                                            width: 7
                                            height: 7
                                            anchors.left: headerText.right
                                            anchors.leftMargin: 5
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: modelData[3] === root.sortKey
                                            descending: root.sortDescending
                                            arrowColor: Theme.text
                                        }
                                    }

                                    Rectangle {
                                        width: headerContent.width
                                        height: 2
                                        anchors.horizontalCenter: headerContent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        radius: 4
                                        visible: modelData[3] === root.sortKey
                                        color: Theme.accent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: modelData[3].length > 0
                                        hoverEnabled: true
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.setSort(modelData[3])
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        id: processList

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        focus: root.active
                        spacing: 1
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.filteredProcesses
                        cacheBuffer: height * 2
                        highlightFollowsCurrentItem: false
                        keyNavigationEnabled: true
                        reuseItems: true

                        Keys.onPressed: event => {
                            const pageStep = Math.max(1, Math.floor(processList.height / 42) - 1);

                            if (event.key === Qt.Key_Down) {
                                root.moveProcessSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.moveProcessSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left) {
                                root.requestStatistics();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right) {
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageDown) {
                                root.moveProcessSelection(pageStep);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                root.moveProcessSelection(-pageStep);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.selectedProcess)
                                    SystemStats.killProcess(root.selectedProcess.pid, false);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Slash) {
                                root.focusSearch();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Home) {
                                root.selectProcess(0);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_End) {
                                root.selectProcess(root.filteredProcesses.length - 1);
                                event.accepted = true;
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: processList.width
                            height: 42
                            color: root.selectedProcess && root.selectedProcess.pid === modelData.pid ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 140
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    root.selectProcess(index);
                                    root.focusList();
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    Layout.preferredWidth: 56
                                    text: modelData.pid
                                    color: Theme.subtext
                                    font.pixelSize: 12
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: Theme.text
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.command
                                        color: Theme.subtext
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 64
                                    text: `${modelData.cpu.toFixed(1)}%`
                                    color: Theme.accent
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 64
                                    text: `${modelData.memory.toFixed(1)}%`
                                    color: Theme.accent2
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 72
                                    text: `${modelData.rssMiB.toFixed(modelData.rssMiB >= 100 ? 0 : 1)} MiB`
                                    color: Theme.text
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 70
                                    text: modelData.gpuMemoryMiB > 0 ? `${modelData.gpuMemoryMiB} MiB` : "--"
                                    color: modelData.gpuMemoryMiB > 0 ? Theme.swatch2 : Theme.subtext
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                }

                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 26
                                    radius: 4
                                    color: killMouse.containsMouse ? Qt.rgba(0.95, 0.42, 0.48, 0.24) : Qt.rgba(0.95, 0.42, 0.48, 0.1)
                                    border.width: 1
                                    border.color: Qt.rgba(0.95, 0.42, 0.48, 0.36)

                                    LucideIcon {
                                        anchors.centerIn: parent
                                        icon: Icons.circleX
                                        iconSize: 14
                                        color: "#f38ba8"
                                    }

                                    MouseArea {
                                        id: killMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: SystemStats.killProcess(modelData.pid, false)
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                radius: 4
                color: Qt.alpha(Theme.surface, 0.72)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: root.selectedProcess ? root.selectedProcess.name : "No process"
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Repeater {
                        model: root.selectedProcess ? [["PID", root.selectedProcess.pid], ["PPID", root.selectedProcess.ppid], ["State", root.selectedProcess.state], ["Runtime", root.selectedProcess.runtime], ["CPU", `${root.selectedProcess.cpu.toFixed(1)}%`], ["RAM", `${root.selectedProcess.memory.toFixed(1)}%`], ["RSS", `${root.selectedProcess.rssMiB.toFixed(1)} MiB`], ["GPU memory", root.selectedProcess.gpuMemoryMiB > 0 ? `${root.selectedProcess.gpuMemoryMiB} MiB` : "Unavailable"]] : []

                        RowLayout {
                            required property var modelData

                            Layout.fillWidth: true

                            Text {
                                text: modelData[0]
                                color: Theme.subtext
                                font.pixelSize: 12
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                Layout.maximumWidth: 160
                                text: modelData[1]
                                color: Theme.text
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.border
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.selectedProcess ? root.selectedProcess.command : ""
                        color: Theme.subtext
                        font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 4
                            color: termArea.containsMouse ? Qt.rgba(0.95, 0.42, 0.48, 0.22) : Qt.rgba(0.95, 0.42, 0.48, 0.12)
                            border.width: 1
                            border.color: Qt.rgba(0.95, 0.42, 0.48, 0.38)
                            enabled: root.selectedProcess !== null
                            opacity: enabled ? 1 : 0.45

                            Text {
                                anchors.centerIn: parent
                                text: "TERM"
                                color: "#f38ba8"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: termArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (root.selectedProcess)
                                        SystemStats.killProcess(root.selectedProcess.pid, false);
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 4
                            color: killForceArea.containsMouse ? Qt.rgba(0.95, 0.42, 0.48, 0.3) : Qt.rgba(0.95, 0.42, 0.48, 0.16)
                            border.width: 1
                            border.color: Qt.rgba(0.95, 0.42, 0.48, 0.5)
                            enabled: root.selectedProcess !== null
                            opacity: enabled ? 1 : 0.45

                            Text {
                                anchors.centerIn: parent
                                text: "KILL"
                                color: "#f38ba8"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: killForceArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (root.selectedProcess)
                                        SystemStats.killProcess(root.selectedProcess.pid, true);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: refreshFilteredProcesses()
}
