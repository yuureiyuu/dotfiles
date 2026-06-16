pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../services"

Flickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: layout.implicitHeight
    property var passwordNetwork: null
    property string wifiPassword: ""
    property var expandedBluetoothDevice: null
    property real stableContentY: 0
    property bool restoringScroll: false

    onContentYChanged: {
        if (!restoringScroll)
            stableContentY = contentY;
    }

    onContentHeightChanged: restoreScrollTimer.restart()

    ColumnLayout {
        id: layout

        width: root.width
        spacing: 10

        Section {
            title: SettingsService.t("Theme")
            iconName: Theme.darkMode ? "moon" : "sun"

            ToggleRow {
                label: Theme.darkMode ? SettingsService.t("Dark theme") : SettingsService.t("Light theme")
                checked: Theme.darkMode
                onToggled: checked => Theme.applyDarkMode(checked)
            }
        }

        Section {
            title: SettingsService.t("Bluetooth")
            iconName: "bluetooth"

            ToggleRow {
                label: SettingsService.t("Bluetooth enabled")
                checked: Bluetooth.defaultAdapter?.enabled ?? false
                enabledState: !!Bluetooth.defaultAdapter
                onToggled: checked => {
                    if (Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.enabled = checked;
                }
            }

            ToggleRow {
                label: SettingsService.t("Discovery")
                checked: Bluetooth.defaultAdapter?.discovering ?? false
                enabledState: Bluetooth.defaultAdapter?.enabled ?? false
                onToggled: checked => {
                    if (Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.discovering = checked;
                }
            }

            Text {
                Layout.fillWidth: true
                visible: [...Bluetooth.devices.values].some(device => device.connected)
                text: SettingsService.t("Connected device")
                color: Theme.subtext
                font.pixelSize: 11
            }

            Repeater {
                model: [...Bluetooth.devices.values].filter(device => device.connected).sort((a, b) => (a.name || "").localeCompare(b.name || ""))

                ColumnLayout {
                    id: connectedBluetoothItem

                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6

                    DeviceRow {
                        iconName: "bluetooth"
                        title: connectedBluetoothItem.modelData.name || connectedBluetoothItem.modelData.address || "Bluetooth device"
                        subtitle: SettingsService.t("Connected")
                        active: true
                        actionIcon: "unlink"
                        enabledState: Bluetooth.defaultAdapter?.enabled ?? false
                        onClicked: connectedBluetoothItem.modelData.disconnect()
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                        }

                        PanelButton {
                            text: SettingsService.t("Forget")
                            iconName: "trash-2"
                            enabledState: connectedBluetoothItem.modelData.paired ?? false
                            onClicked: connectedBluetoothItem.modelData.forget()
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: SettingsService.t("Devices")
                color: Theme.subtext
                font.pixelSize: 11
            }

            Repeater {
                model: [...Bluetooth.devices.values].filter(device => !device.connected).sort((a, b) => (b.paired - a.paired) || (a.name || "").localeCompare(b.name || "")).slice(0, 8)

                ColumnLayout {
                    id: bluetoothDeviceItem

                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6

                    DeviceRow {
                        iconName: "bluetooth"
                        title: bluetoothDeviceItem.modelData.name || bluetoothDeviceItem.modelData.address || "Bluetooth device"
                        subtitle: bluetoothDeviceItem.modelData.paired ? SettingsService.t("Paired") : SettingsService.t("Available")
                        active: false
                        actionIcon: "link"
                        actionVisible: root.expandedBluetoothDevice !== bluetoothDeviceItem.modelData
                        enabledState: Bluetooth.defaultAdapter?.enabled ?? false
                        onClicked: root.expandedBluetoothDevice = root.expandedBluetoothDevice === bluetoothDeviceItem.modelData ? null : bluetoothDeviceItem.modelData
                    }

                    Rectangle {
                        visible: root.expandedBluetoothDevice === bluetoothDeviceItem.modelData
                        Layout.fillWidth: true
                        implicitHeight: visible ? 42 : 0
                        radius: 5
                        color: Qt.alpha(Theme.surface, 0.35)
                        border.width: 1
                        border.color: Qt.alpha(Theme.text, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                            }

                            PanelButton {
                                text: bluetoothDeviceItem.modelData.paired ? SettingsService.t("Forget") : SettingsService.t("Pair")
                                iconName: bluetoothDeviceItem.modelData.paired ? "trash-2" : "plus"
                                enabledState: Bluetooth.defaultAdapter?.enabled ?? false
                                onClicked: {
                                    if (bluetoothDeviceItem.modelData.paired)
                                        bluetoothDeviceItem.modelData.forget();
                                    else
                                        bluetoothDeviceItem.modelData.pair();
                                }
                            }

                            PanelButton {
                                text: SettingsService.t("Connect")
                                iconName: "link"
                                enabledState: Bluetooth.defaultAdapter?.enabled ?? false
                                prominent: true
                                onClicked: {
                                    bluetoothDeviceItem.modelData.connect();
                                    root.expandedBluetoothDevice = null;
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Bluetooth.defaultAdapter === null || Bluetooth.devices.values.length === 0
                text: Bluetooth.defaultAdapter === null ? "Bluetooth adapter is not available." : "No devices found."
                color: Theme.subtext
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }

        Section {
            title: "Wi-Fi"
            iconName: Network.wifiEnabled ? "wifi-high" : "wifi-off"

            ToggleRow {
                label: "Wi-Fi enabled"
                checked: Network.wifiEnabled
                onToggled: checked => Network.setWifiEnabled(checked)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: Network.activeNetwork ? `Connected to ${Network.activeNetwork.ssid}` : `${Network.networks.length} networks available`
                    color: Theme.subtext
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                PanelButton {
                    text: Network.scanning ? "Scanning" : "Scan"
                    iconName: "wifi-sync"
                    enabledState: Network.wifiEnabled && !Network.scanning
                    onClicked: Network.rescan()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !!Network.activeNetwork
                text: "Connected network"
                color: Theme.subtext
                font.pixelSize: 11
            }

            DeviceRow {
                visible: !!Network.activeNetwork
                iconName: "wifi-high"
                title: Network.activeNetwork?.ssid || ""
                subtitle: `${Network.activeNetwork?.strength ?? 0}%${Network.activeNetwork?.security?.length ? " - secured" : ""}`
                active: true
                actionIcon: "unlink"
                enabledState: Network.wifiEnabled
                onClicked: Network.disconnect()
            }

            RowLayout {
                visible: !!Network.activeNetwork
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                PanelButton {
                    text: "Forget"
                    iconName: "trash-2"
                    enabledState: !!Network.activeNetwork
                    onClicked: Network.forget(Network.activeNetwork)
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Networks"
                color: Theme.subtext
                font.pixelSize: 11
            }

            Repeater {
                model: Network.networks.filter(network => !network.active).slice(0, 10)

                ColumnLayout {
                    id: wifiNetworkItem

                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6

                    DeviceRow {
                        iconName: wifiNetworkItem.modelData.strength > 70 ? "wifi-high" : (wifiNetworkItem.modelData.strength > 35 ? "wifi" : "wifi-low")
                        title: wifiNetworkItem.modelData.ssid
                        subtitle: `${wifiNetworkItem.modelData.strength}%${wifiNetworkItem.modelData.security.length ? " - secured" : ""}`
                        active: false
                        actionIcon: "link"
                        actionVisible: root.passwordNetwork?.ssid !== wifiNetworkItem.modelData.ssid
                        enabledState: Network.wifiEnabled
                        onClicked: {
                            if (wifiNetworkItem.modelData.security.length) {
                                root.passwordNetwork = root.passwordNetwork?.ssid === wifiNetworkItem.modelData.ssid ? null : wifiNetworkItem.modelData;
                                root.wifiPassword = "";
                            } else {
                                Network.connect(wifiNetworkItem.modelData);
                            }
                        }
                    }

                    Rectangle {
                        visible: root.passwordNetwork?.ssid === wifiNetworkItem.modelData.ssid
                        Layout.fillWidth: true
                        implicitHeight: visible ? 42 : 0
                        radius: 5
                        color: Qt.alpha(Theme.surface, 0.35)
                        border.width: 1
                        border.color: Qt.alpha(Theme.text, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            TextInput {
                                Layout.fillWidth: true
                                text: root.wifiPassword
                                color: Theme.text
                                selectionColor: Qt.alpha(Theme.accent, 0.45)
                                selectedTextColor: Theme.text
                                echoMode: TextInput.Password
                                font.pixelSize: 12
                                clip: true
                                onTextChanged: root.wifiPassword = text

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: parent.text.length === 0
                                    text: "Password"
                                    color: Theme.subtext
                                    font.pixelSize: 12
                                }
                            }

                            PanelButton {
                                text: "Join"
                                iconName: "link"
                                prominent: true
                                enabledState: root.wifiPassword.length > 0
                                onClicked: {
                                    Network.connectWithPassword(wifiNetworkItem.modelData, root.wifiPassword);
                                    root.passwordNetwork = null;
                                    root.wifiPassword = "";
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Network.networks.filter(network => !network.active).length === 0
                text: Network.wifiEnabled ? "No Wi-Fi networks found." : "Wi-Fi is disabled."
                color: Theme.subtext
                font.pixelSize: 12
            }
        }

        Section {
            title: "Ethernet"
            iconName: "ethernet-port"

            Repeater {
                model: Network.ethernetDevices

                DeviceRow {
                    required property var modelData

                    iconName: "ethernet-port"
                    title: modelData.connection && modelData.connection !== "--" ? modelData.connection : modelData.device
                    subtitle: modelData.connected ? "Connected" : modelData.state
                    active: modelData.connected
                    actionIcon: modelData.connected ? "check" : "circle-alert"
                    enabledState: false
                }
            }

            Text {
                Layout.fillWidth: true
                visible: Network.ethernetDevices.length === 0
                text: "No ethernet device detected."
                color: Theme.subtext
                font.pixelSize: 12
            }
        }

        Section {
            title: "Brightness"
            iconName: "sun"

            SliderRow {
                label: "Display brightness"
                iconName: "sun"
                value: Brightness.value
                enabledState: Brightness.available
                onMoved: value => Brightness.setValue(value)
            }
        }
    }

    Timer {
        id: restoreScrollTimer

        interval: 0
        repeat: false
        onTriggered: {
            root.restoringScroll = true;
            root.contentY = Math.max(0, Math.min(root.stableContentY, Math.max(0, root.contentHeight - root.height)));
            root.restoringScroll = false;
        }
    }
}
