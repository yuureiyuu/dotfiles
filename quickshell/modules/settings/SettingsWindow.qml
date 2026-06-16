pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../barPanel"

PanelWindow {
    id: root

    required property var settings
    property int activePage: 0
    readonly property var pages: [
        { icon: "sliders-horizontal", label: SettingsService.t("General") },
        { icon: "server-cog", label: SettingsService.t("Services") },
        { icon: "image", label: SettingsService.t("Background") },
        { icon: "panel-bottom", label: SettingsService.t("Interface") },
        { icon: "circle-alert", label: SettingsService.t("About") }
    ]

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function pageComponent(index) {
        if (index === 1)
            return servicesPage;
        if (index === 2)
            return backgroundPage;
        if (index === 3)
            return interfacePage;
        if (index === 4)
            return aboutPage;
        return generalPage;
    }

    HyprlandFocusGrab {
        active: false
        windows: [root]
        onCleared: root.settings.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: root.settings.revealProgress > 0.98
            onClicked: root.settings.close()
        }

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 26
            spread: 0
            offset: Qt.vector2d(0, 8)
            color: "#42000000"
            opacity: root.settings.revealProgress
            cached: false
        }

        Rectangle {
            id: card

            width: Math.min(parent.width - 36, SettingsService.scaled(980))
            height: Math.min(parent.height - 34, SettingsService.scaled(620))
            anchors.centerIn: parent
            anchors.verticalCenterOffset: (1 - root.settings.revealProgress) * 24
            scale: SettingsService.interfaceScale * (0.98 + root.settings.revealProgress * 0.02)
            opacity: root.settings.revealProgress
            radius: 6
            clip: true
            color: Theme.base
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.30)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: mouse => mouse.accepted = true
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 86
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.16) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.accent, 0) }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Rectangle {
                    Layout.preferredWidth: 146
                    Layout.fillHeight: true
                    radius: 5
                    color: Qt.alpha(Theme.mantle, 0.88)
                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.08)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: SettingsService.t("Settings")
                            color: Theme.text
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "ajisai-shell"
                            color: Theme.subtext
                            font.pixelSize: 12
                        }

                        Repeater {
                            model: root.pages.slice(0, 4)

                            delegate: SettingsNavButton {
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                iconName: modelData.icon
                                label: modelData.label
                                active: root.activePage === index
                                onClicked: root.activePage = index
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        SettingsNavButton {
                            Layout.fillWidth: true
                            iconName: root.pages[4].icon
                            label: root.pages[4].label
                            active: root.activePage === 4
                            onClicked: root.activePage = 4
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ThemedSvgIcon {
                            iconName: root.pages[root.activePage].icon
                            iconSize: 24
                            color: Theme.accent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.pages[root.activePage].label
                            color: Theme.text
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }

                        IconButton {
                            iconName: "x"
                            onClicked: root.settings.close()
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: root.pageComponent(root.activePage)
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.settings.close();
                    event.accepted = true;
                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                    root.activePage = event.key - Qt.Key_1;
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
        }
    }

    Component {
        id: generalPage

        SettingsPage {
            SettingsSection {
                title: SettingsService.t("Shell")
                iconName: "settings"

                Text {
                    Layout.fillWidth: true
                    text: SettingsService.t("Language")
                    color: Theme.subtext
                    font.pixelSize: 11
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("System")
                        active: SettingsService.shellLanguage === "system"
                        onClicked: SettingsService.setShellLanguage("system")
                    }

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("English")
                        active: SettingsService.shellLanguage === "en"
                        onClicked: SettingsService.setShellLanguage("en")
                    }

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: "Русский"
                        active: SettingsService.shellLanguage === "ru"
                        onClicked: SettingsService.setShellLanguage("ru")
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: SettingsService.t("Keyboard layout")
                    color: Theme.subtext
                    font.pixelSize: 11
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("Current")
                        active: SettingsService.keyboardLayout === "current"
                        onClicked: SettingsService.setKeyboardLayout("current")
                    }

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: "US"
                        active: SettingsService.keyboardLayout === "us"
                        onClicked: SettingsService.setKeyboardLayout("us")
                    }

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: "RU"
                        active: SettingsService.keyboardLayout === "ru"
                        onClicked: SettingsService.setKeyboardLayout("ru")
                    }

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: "KZ"
                        active: SettingsService.keyboardLayout === "kz"
                        onClicked: SettingsService.setKeyboardLayout("kz")
                    }
                }

                ToggleRow {
                    label: SettingsService.t("Animations")
                    checked: SettingsService.animationsEnabled
                    onToggled: checked => SettingsService.animationsEnabled = checked
                }

                ToggleRow {
                    label: SettingsService.t("24-hour clock")
                    checked: SettingsService.clock24h
                    onToggled: checked => SettingsService.clock24h = checked
                }

                ToggleRow {
                    label: SettingsService.t("Notifications")
                    checked: SettingsService.showNotifications
                    onToggled: checked => SettingsService.showNotifications = checked
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("Reset")
                        active: false
                        onClicked: SettingsService.resetGeneral()
                    }
                }
            }
        }
    }

    Component {
        id: servicesPage

        SettingsPage {
            SettingsSection {
                title: SettingsService.t("Services")
                iconName: "server-cog"

                ToggleRow {
                    label: SettingsService.t("Weather")
                    checked: SettingsService.weatherService
                    onToggled: checked => SettingsService.weatherService = checked
                }

                ToggleRow {
                    label: SettingsService.t("System stats")
                    checked: SettingsService.systemStatsService
                    onToggled: checked => SettingsService.systemStatsService = checked
                }

                ToggleRow {
                    label: SettingsService.t("Now playing")
                    checked: SettingsService.nowPlayingService
                    onToggled: checked => SettingsService.nowPlayingService = checked
                }

                ToggleRow {
                    label: SettingsService.t("Battery")
                    checked: SettingsService.batteryService
                    onToggled: checked => SettingsService.batteryService = checked
                }
            }
        }
    }

    Component {
        id: backgroundPage

        SettingsPage {
            SettingsSection {
                title: SettingsService.t("Wallpaper")
                iconName: "image"

                ToggleRow {
                    label: SettingsService.t("Desktop clock")
                    checked: SettingsService.desktopClock
                    onToggled: checked => SettingsService.desktopClock = checked
                }

                ToggleRow {
                    label: SettingsService.t("Wallpaper dim")
                    checked: SettingsService.wallpaperDim
                    onToggled: checked => SettingsService.wallpaperDim = checked
                }

                SliderRow {
                    label: SettingsService.t("Background blur")
                    iconName: "sparkles"
                    value: SettingsService.backgroundBlur
                    onMoved: value => SettingsService.setBackgroundBlur(value)
                }

                Text {
                    Layout.fillWidth: true
                    text: Theme.currentWallpaper.length ? Theme.currentWallpaper : SettingsService.t("No wallpaper selected")
                    color: Theme.subtext
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    Component {
        id: interfacePage

        SettingsPage {
            SettingsSection {
                title: SettingsService.t("Interface")
                iconName: "panel-bottom"

                ToggleRow {
                    label: SettingsService.t("Island")
                    checked: SettingsService.islandEnabled
                    onToggled: checked => SettingsService.islandEnabled = checked
                }

                ToggleRow {
                    label: SettingsService.t("Compact island")
                    checked: SettingsService.compactIsland
                    enabledState: SettingsService.islandEnabled
                    onToggled: checked => SettingsService.compactIsland = checked
                }

                Text {
                    Layout.fillWidth: true
                    text: SettingsService.t("Bar position")
                    color: Theme.subtext
                    font.pixelSize: 11
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("Right")
                        active: SettingsService.barPosition === "right"
                        onClicked: SettingsService.setBarPosition("right")
                    }

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("Top")
                        active: SettingsService.barPosition === "top"
                        onClicked: SettingsService.setBarPosition("top")
                    }

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("Left")
                        active: SettingsService.barPosition === "left"
                        onClicked: SettingsService.setBarPosition("left")
                    }
                }

                SliderRow {
                    label: SettingsService.t("Interface scale")
                    iconName: "maximize"
                    value: SettingsService.interfaceScale - 0.75
                    to: 0.5
                    onMoved: value => SettingsService.interfaceScale = 0.75 + value
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ChoiceButton {
                        Layout.fillWidth: true
                        text: SettingsService.t("Reset")
                        active: false
                        onClicked: SettingsService.resetInterface()
                    }
                }
            }
        }
    }

    Component {
        id: aboutPage

        SettingsPage {
            Item {
                Layout.fillWidth: true
                Layout.minimumHeight: 420

                ColumnLayout {
                    width: Math.min(parent.width, 520)
                    anchors.centerIn: parent
                    spacing: 14

                    ThemedSvgIcon {
                        Layout.alignment: Qt.AlignHCenter
                        iconName: "flower"
                        iconSize: 58
                        color: Theme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "ajisai-shell"
                        color: Theme.text
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "This shell is only an alpha version of ajisai-shell."
                        color: Theme.subtext
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "made by Yū & Sora"
                        color: Theme.accent
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    component SettingsPage: Flickable {
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, pageLayout.implicitHeight)
        boundsBehavior: Flickable.StopAtBounds

        default property alias content: pageLayout.data

        ColumnLayout {
            id: pageLayout

            width: parent.width
            spacing: 10
        }
    }

    component SettingsSection: Section {}

    component ChoiceButton: Rectangle {
        id: choice

        required property string text
        property bool active: false
        signal clicked

        implicitHeight: 32
        radius: 5
        color: active ? Qt.alpha(Theme.accent, 0.22) : (choiceMouse.containsMouse ? Qt.alpha(Theme.text, 0.08) : Qt.alpha(Theme.surface, 0.42))
        border.width: 1
        border.color: active ? Qt.alpha(Theme.accent, 0.48) : Qt.alpha(Theme.text, 0.09)

        Text {
            anchors.centerIn: parent
            width: parent.width - 12
            text: choice.text
            color: choice.active ? Theme.text : Theme.subtext
            font.pixelSize: 12
            font.weight: choice.active ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        MouseArea {
            id: choiceMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: choice.clicked()
        }
    }

    component SettingsNavButton: Item {
        id: nav

        required property string iconName
        required property string label
        property bool active: false
        signal clicked

        implicitHeight: 38

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: nav.active ? Qt.alpha(Theme.accent, 0.18) : (navMouse.containsMouse ? Qt.alpha(Theme.text, 0.07) : "transparent")
            border.width: nav.active ? 1 : 0
            border.color: Qt.alpha(Theme.accent, 0.38)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            ThemedSvgIcon {
                iconName: nav.iconName
                iconSize: 16
                color: nav.active ? Theme.accent : Theme.icon
            }

            Text {
                Layout.fillWidth: true
                text: nav.label
                color: nav.active ? Theme.text : Theme.subtext
                font.pixelSize: 12
                font.weight: nav.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: navMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: nav.clicked()
        }
    }
}
