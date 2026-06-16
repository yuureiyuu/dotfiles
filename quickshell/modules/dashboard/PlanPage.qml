pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../../services"

Item {
    id: root

    readonly property date today: new Date()
    readonly property date minMonth: new Date(today.getFullYear() - 1, today.getMonth(), 1)
    readonly property date maxMonth: new Date(today.getFullYear() + 1, today.getMonth(), 1)
    property date visibleMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: new Date(today.getFullYear(), today.getMonth(), today.getDate())
    readonly property string selectedDateKey: DashboardTodo.dateKey(selectedDate)
    readonly property bool selectedDateWritable: startOfDay(selectedDate).getTime() >= startOfDay(today).getTime()
    readonly property int visibleCellCount: Math.ceil((firstDayOffset(visibleMonth) + daysInMonth(visibleMonth)) / 7) * 7
    readonly property int timerDisplaySeconds: DashboardTimer.running ? DashboardTimer.remainingSeconds : DashboardTimer.initialSeconds

    function startOfDay(dateValue) {
        return new Date(dateValue.getFullYear(), dateValue.getMonth(), dateValue.getDate());
    }

    function daysInMonth(dateValue) {
        return new Date(dateValue.getFullYear(), dateValue.getMonth() + 1, 0).getDate();
    }

    function firstDayOffset(dateValue) {
        const raw = new Date(dateValue.getFullYear(), dateValue.getMonth(), 1).getDay();
        return raw === 0 ? 6 : raw - 1;
    }

    function dateFromCell(index) {
        return new Date(visibleMonth.getFullYear(), visibleMonth.getMonth(), index - firstDayOffset(visibleMonth) + 1);
    }

    function sameDay(left, right) {
        return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
    }

    function monthOffset(delta) {
        const next = new Date(visibleMonth.getFullYear(), visibleMonth.getMonth() + delta, 1);
        if (next < minMonth || next > maxMonth)
            return;
        visibleMonth = next;
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 14
        columnSpacing: 14

        DashboardPanel {
            Layout.fillWidth: true
            Layout.preferredWidth: 430
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    DashboardToolButton {
                        enabled: root.visibleMonth > root.minMonth
                        iconName: "chevron-left"
                        onClicked: root.monthOffset(-1)
                    }

                    PanelHeader {
                        Layout.fillWidth: true
                        iconName: "calendar-days"
                        title: Qt.locale().toString(root.visibleMonth, "MMMM yyyy")
                    }

                    DashboardToolButton {
                        enabled: root.visibleMonth < root.maxMonth
                        iconName: "chevron-right"
                        onClicked: root.monthOffset(1)
                    }
                }

                Item {
                    id: calendarField

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    readonly property int dayRows: Math.ceil(root.visibleCellCount / 7)
                    readonly property int spacing: 6
                    readonly property int headerHeight: 18
                    readonly property int cellSize: Math.max(16, Math.floor(Math.min((width - spacing * 6) / 7, (height - headerHeight - spacing * dayRows) / dayRows)))

                    Grid {
                        id: calendarGrid

                        width: calendarField.cellSize * 7 + columnSpacing * 6
                        height: calendarField.headerHeight + calendarField.cellSize * calendarField.dayRows + rowSpacing * calendarField.dayRows
                        anchors.centerIn: calendarField
                        columns: 7
                        columnSpacing: calendarField.spacing
                        rowSpacing: calendarField.spacing

                        Repeater {
                            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                            Text {
                                required property string modelData

                                width: calendarField.cellSize
                                height: calendarField.headerHeight
                                text: modelData
                                color: Theme.subtext
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Repeater {
                            model: root.visibleCellCount

                            Rectangle {
                                id: dayCell

                                required property int index
                                readonly property date cellDate: root.dateFromCell(index)
                                readonly property bool inMonth: cellDate.getMonth() === root.visibleMonth.getMonth()
                                readonly property bool current: root.sameDay(cellDate, root.today)
                                readonly property bool selected: root.sameDay(cellDate, root.selectedDate)
                                readonly property int taskCount: DashboardTodo.countForDate(DashboardTodo.dateKey(cellDate))

                                width: calendarField.cellSize
                                height: calendarField.cellSize
                                radius: 4
                                color: selected ? Qt.alpha(Theme.accent, 0.28) : (current ? Qt.alpha(Theme.accent2, 0.20) : Qt.alpha(Theme.surface, inMonth ? 0.56 : 0.16))
                                border.width: selected || current ? 1 : 0
                                border.color: selected ? Qt.alpha(Theme.accent, 0.62) : Qt.alpha(Theme.accent2, 0.42)
                                opacity: inMonth ? 1 : 0.48

                                Text {
                                    anchors.fill: parent
                                    text: dayCell.cellDate.getDate()
                                    color: dayCell.selected || dayCell.current ? Theme.text : Theme.subtext
                                    font.family: "monospace"
                                    font.pixelSize: Math.max(10, Math.min(13, dayCell.height * 0.34))
                                    font.weight: dayCell.selected ? Font.DemiBold : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    visible: dayCell.taskCount > 0
                                    color: Theme.accent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedDate = dayCell.cellDate
                                }
                            }
                        }
                    }
                }
            }
        }

        DashboardPanel {
            Layout.fillWidth: true
            Layout.preferredWidth: 430
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                PanelHeader {
                    Layout.fillWidth: true
                    iconName: "list-todo"
                    title: `To-do / ${Qt.locale().toString(root.selectedDate, "dd MMM")}`
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 4
                    color: Qt.alpha(Theme.surface, 0.86)
                    border.width: 1
                    border.color: Qt.alpha(Theme.border, 0.78)
                    opacity: root.selectedDateWritable ? 1 : 0.55

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 6
                        spacing: 8

                        TextField {
                            id: taskInput

                            Layout.fillWidth: true
                            enabled: root.selectedDateWritable
                            color: Theme.text
                            placeholderText: root.selectedDateWritable ? SettingsService.t("Add task") : SettingsService.t("Past date")
                            placeholderTextColor: Theme.subtext
                            background: Item {}
                            selectByMouse: true
                            onAccepted: {
                                DashboardTodo.addTask(text, root.selectedDateKey);
                                text = "";
                            }
                        }

                        DashboardToolButton {
                            enabled: root.selectedDateWritable
                            iconName: "plus"
                            onClicked: {
                                DashboardTodo.addTask(taskInput.text, root.selectedDateKey);
                                taskInput.text = "";
                            }
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: DashboardTodo.itemsForDate(root.selectedDateKey)

                    delegate: Rectangle {
                        required property var modelData

                        width: ListView.view.width
                        height: 48
                        radius: 4
                        color: Qt.alpha(Theme.surface, modelData.done ? 0.38 : 0.72)
                        border.width: 1
                        border.color: Qt.alpha(Theme.border, 0.58)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 6
                            spacing: 9

                            DashboardToolButton {
                                iconName: modelData.done ? "circle-check" : "circle-off"
                                onClicked: DashboardTodo.toggleById(modelData.id)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.content
                                color: modelData.done ? Theme.subtext : Theme.text
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                font.strikeout: modelData.done
                            }

                            DashboardToolButton {
                                iconName: "trash-2"
                                danger: true
                                onClicked: DashboardTodo.removeById(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        DashboardPanel {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.preferredHeight: 218

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                ColumnLayout {
                    Layout.preferredWidth: 226
                    Layout.fillHeight: true
                    spacing: 10

                    PanelHeader {
                        Layout.fillWidth: true
                        iconName: "timer-reset"
                        title: SettingsService.t("Timer")
                    }

                    Text {
                        Layout.fillWidth: true
                        text: DashboardTimer.active ? (DashboardTimer.running ? SettingsService.t("Running") : SettingsService.t("Paused")) : SettingsService.t("Ready")
                        color: DashboardTimer.active ? Theme.text : Theme.subtext
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: DashboardTimer.active ? SettingsService.t("remaining") : SettingsService.t("selected")
                            color: Theme.subtext
                            opacity: 0.78
                            font.pixelSize: 12
                        }

                        Text {
                            text: DashboardTimer.formatFull(DashboardTimer.active ? DashboardTimer.remainingSeconds : DashboardTimer.initialSeconds)
                            color: Theme.text
                            font.family: "monospace"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Qt.alpha(Theme.surface, 0.42)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: DashboardTimer.initialSeconds > 0 ? Math.max(parent.height, parent.width * DashboardTimer.progress) : 0
                            radius: parent.radius
                            color: Theme.mixColor(Theme.accent, Theme.accent2, DashboardTimer.active ? 0.45 : 0.18)

                            Behavior on width {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: DashboardTimer.active ? SettingsService.t("Focus session in progress.") : (DashboardTimer.initialSeconds > 0 ? SettingsService.t("Duration prepared.") : SettingsService.t("No duration selected."))
                        color: Theme.subtext
                        opacity: 0.66
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 52
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    Item {
                        Layout.fillHeight: true
                    }

                    DashboardToolButton {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        iconName: DashboardTimer.running ? "pause" : "play"
                        colorfulPressEffect: true
                        onClicked: DashboardTimer.toggle()
                    }

                    DashboardToolButton {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        iconName: "timer-reset"
                        colorfulPressEffect: true
                        onClicked: DashboardTimer.reset()
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 360
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: DashboardTimer.active ? 126 : 0
                        visible: DashboardTimer.active
                        text: DashboardTimer.formatFull(DashboardTimer.remainingSeconds)
                        color: Theme.text
                        font.pixelSize: 48
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 360
                        Layout.preferredHeight: DashboardTimer.active ? 0 : 126
                        visible: !DashboardTimer.active
                        spacing: 10

                        TimePickerColumn {
                            Layout.preferredWidth: 108
                            Layout.preferredHeight: 126
                            label: SettingsService.t("hours")
                            value: Math.floor(root.timerDisplaySeconds / 3600)
                            maxValue: 99
                            onChangeRequested: delta => DashboardTimer.setParts(Math.floor(DashboardTimer.initialSeconds / 3600) + delta, Math.floor((DashboardTimer.initialSeconds % 3600) / 60), DashboardTimer.initialSeconds % 60)
                        }

                        TimePickerColumn {
                            Layout.preferredWidth: 108
                            Layout.preferredHeight: 126
                            label: SettingsService.t("min")
                            value: Math.floor((root.timerDisplaySeconds % 3600) / 60)
                            maxValue: 59
                            onChangeRequested: delta => DashboardTimer.setParts(Math.floor(DashboardTimer.initialSeconds / 3600), Math.floor((DashboardTimer.initialSeconds % 3600) / 60) + delta, DashboardTimer.initialSeconds % 60)
                        }

                        TimePickerColumn {
                            Layout.preferredWidth: 108
                            Layout.preferredHeight: 126
                            label: SettingsService.t("sec")
                            value: root.timerDisplaySeconds % 60
                            maxValue: 59
                            onChangeRequested: delta => DashboardTimer.setParts(Math.floor(DashboardTimer.initialSeconds / 3600), Math.floor((DashboardTimer.initialSeconds % 3600) / 60), DashboardTimer.initialSeconds % 60 + delta)
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: DashboardTimer.active ? 0 : 34
                        visible: !DashboardTimer.active
                        spacing: 7

                        Repeater {
                            model: DashboardTimer.recentDurations

                            Rectangle {
                                id: presetTile

                                required property int modelData
                                readonly property bool hovered: presetMouse.containsMouse

                                Layout.preferredWidth: 92
                                Layout.fillHeight: true
                                radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: hovered ? Qt.alpha(Theme.accent, 0.58) : Qt.alpha(Theme.border, 0.28)

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 140
                                    }
                                }

                                RectangularShadow {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    blur: presetTile.hovered ? 14 : 8
                                    spread: 0
                                    offset: Qt.vector2d(0, 0)
                                    color: Qt.alpha(Theme.accent, presetTile.hovered ? 0.16 : 0.07)
                                    cached: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: DashboardTimer.formatFull(presetTile.modelData)
                                    color: Theme.text
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: presetMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: DashboardTimer.applyRecent(presetTile.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component TimePickerColumn: Item {
        id: picker

        required property string label
        required property int value
        required property int maxValue
        signal changeRequested(int delta)

        implicitWidth: 108
        implicitHeight: 126

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: picker.label
                color: Theme.subtext
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: String(picker.value).padStart(2, "0")
                    color: Theme.text
                    font.pixelSize: 38
                    font.weight: Font.DemiBold

                    Behavior on text {
                        enabled: false
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: 32
                    text: String(Math.min(picker.maxValue, picker.value + 1)).padStart(2, "0")
                    color: Qt.alpha(Theme.subtext, 0.26)
                    font.pixelSize: 21
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: 32
                    text: String(Math.max(0, picker.value - 1)).padStart(2, "0")
                    color: Qt.alpha(Theme.subtext, 0.26)
                    font.pixelSize: 21
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                if (delta > 0 && picker.value < picker.maxValue)
                    picker.changeRequested(1);
                else if (delta < 0 && picker.value > 0)
                    picker.changeRequested(-1);
                wheel.accepted = true;
            }
        }
    }
}
