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

    required property var hotkeys
    readonly property var sections: [
        {
            title: "Quickshell",
            icon: "sparkles",
            items: [
                {
                    keys: ["Super", "A"],
                    title: "Launcher",
                    description: "Открыть поиск приложений и режим выбора обоев."
                },
                {
                    keys: ["Super", "Shift", "D"],
                    title: "Dashboard",
                    description: "Панель с домашним экраном, планом и рабочими пространствами."
                },
                {
                    keys: ["Super", "Shift", "P"],
                    title: "Control Panel",
                    description: "Быстрые переключатели, звук и история уведомлений."
                },
                {
                    keys: ["Super", "Shift", "S"],
                    title: "Shell Setting",
                    description: "Тема, фон, сервисы и параметры интерфейса."
                },
                {
                    keys: ["Super", "Shift", "M"],
                    title: "System Monitor",
                    description: "Нагрузка, память, сеть и процессы."
                },
                {
                    keys: ["Super", "Shift", "H"],
                    title: "Hotkeys",
                    description: "Это окно со всеми основными сочетаниями."
                },
                {
                    keys: ["Super", "L"],
                    title: "Screenlock",
                    description: "Заблокировать текущую сессию."
                },
                {
                    keys: ["Super", "Insert"],
                    title: "Screenshot",
                    description: "Выбрать область и сохранить снимок в Pictures и буфер."
                }
            ]
        },
        {
            title: "Windows",
            icon: "app-window",
            items: [
                {
                    keys: ["Super", "Q"],
                    title: "Закрыть окно",
                    description: "Закрыть активное окно."
                },
                {
                    keys: ["Super", "V"],
                    title: "Float",
                    description: "Переключить плавающий режим активного окна."
                },
                {
                    keys: ["Super", "P"],
                    title: "Pseudo",
                    description: "Переключить pseudo-tiling в dwindle."
                },
                {
                    keys: ["Super", "J"],
                    title: "Разделение",
                    description: "Сменить направление split для следующего окна."
                },
                {
                    keys: ["Super", "Стрелки"],
                    title: "Фокус",
                    description: "Переместить фокус между соседними окнами."
                },
                {
                    keys: ["Super", "Shift", "Стрелки"],
                    title: "Переместить",
                    description: "Передвинуть активное окно в выбранную сторону."
                },
                {
                    keys: ["Super", "Ctrl", "Стрелки"],
                    title: "Размер",
                    description: "Изменить размер активного окна шагом 40 px."
                },
                {
                    keys: ["Super", "ЛКМ/ПКМ"],
                    title: "Drag/resize",
                    description: "Перетащить или изменить размер окна мышью."
                }
            ]
        },
        {
            title: "For apps movement",
            icon: "layout-grid",
            items: [
                {
                    keys: ["Super", "Enter"],
                    title: "Терминал",
                    description: "Запустить foot."
                },
                {
                    keys: ["Super", "E"],
                    title: "Файлы",
                    description: "Открыть Dolphin."
                },
                {
                    keys: ["Super", "F"],
                    title: "Браузер",
                    description: "Запустить Zen Browser через Flatpak."
                },
                {
                    keys: ["Super", "T"],
                    title: "Telegram",
                    description: "Открыть Telegram."
                },
                {
                    keys: ["Super", "M"],
                    title: "Выход",
                    description: "Завершить Hyprland-сессию."
                },
                {
                    keys: ["Super", "1-0"],
                    title: "Workspace",
                    description: "Перейти на рабочее пространство 1-10."
                },
                {
                    keys: ["Super", "Shift", "1-0"],
                    title: "Отправить окно",
                    description: "Переместить активное окно на workspace 1-10."
                },
                {
                    keys: ["Super", "Колесо"],
                    title: "Листать workspace",
                    description: "Переключаться между существующими workspace."
                }
            ]
        },
        {
            title: "Media",
            icon: "sliders-horizontal",
            items: [
                {
                    keys: ["XF86", "Volume"],
                    title: "Громкость",
                    description: "Поднять, опустить или выключить звук."
                },
                {
                    keys: ["XF86", "Mic"],
                    title: "Микрофон",
                    description: "Переключить mute для микрофона."
                },
                {
                    keys: ["XF86", "Brightness"],
                    title: "Яркость",
                    description: "Изменить яркость экрана."
                },
                {
                    keys: ["XF86", "Play/Pause"],
                    title: "Плеер",
                    description: "Пауза или продолжение воспроизведения."
                },
                {
                    keys: ["XF86", "Next/Prev"],
                    title: "Треки",
                    description: "Переключить трек в playerctl-совместимом плеере."
                }
            ]
        }
    ]

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:hotkeys"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    HyprlandFocusGrab {
        active: false
        windows: [root]
        onCleared: root.hotkeys.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.mantle, 0.42 * root.hotkeys.revealProgress)

        MouseArea {
            anchors.fill: parent
            enabled: root.hotkeys.revealProgress > 0.98
            onClicked: root.hotkeys.close()
        }

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 28
            spread: 0
            offset: Qt.vector2d(0, 10)
            color: "#4a000000"
            opacity: root.hotkeys.revealProgress
            cached: false
        }

        Rectangle {
            id: card

            width: Math.min(parent.width - 32, SettingsService.scaled(1020))
            height: Math.min(parent.height - 32, SettingsService.scaled(660))
            anchors.centerIn: parent
            anchors.verticalCenterOffset: (1 - root.hotkeys.revealProgress) * 26
            scale: SettingsService.interfaceScale * (0.965 + root.hotkeys.revealProgress * 0.035)
            opacity: root.hotkeys.revealProgress
            radius: 7
            clip: true
            color: Theme.base
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.34)

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
                height: 124
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.accent, 0.18)
                    }
                    GradientStop {
                        position: 0.52
                        color: Qt.alpha(Theme.accent2, 0.08)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.base, 0)
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 6
                        color: Qt.alpha(Theme.accent, 0.18)
                        border.width: 1
                        border.color: Qt.alpha(Theme.accent, 0.36)

                        ThemedSvgIcon {
                            anchors.centerIn: parent
                            iconName: "keyboard"
                            iconSize: 22
                            color: Theme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Hotkeys"
                            color: Theme.text
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Основные сочетания из hyprland.lua"
                            color: Theme.subtext
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        spacing: 6

                        Repeater {
                            model: [Theme.swatch0, Theme.swatch1, Theme.swatch2, Theme.swatch3, Theme.swatch4]

                            Rectangle {
                                required property var modelData

                                width: 16
                                height: 16
                                radius: 4
                                color: modelData
                                border.width: 1
                                border.color: Qt.alpha(Theme.text, 0.16)
                            }
                        }
                    }

                    IconButton {
                        iconName: "x"
                        onClicked: root.hotkeys.close()
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: card.width < 780 ? 1 : 2
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: root.sections

                        Rectangle {
                            id: sectionRoot

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            radius: 6
                            color: Qt.alpha(index % 2 === 0 ? Theme.mantle : Theme.surface, Theme.darkMode ? 0.74 : 0.56)
                            border.width: 1
                            border.color: Qt.alpha(Theme.text, 0.08)
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    ThemedSvgIcon {
                                        iconName: sectionRoot.modelData.icon
                                        iconSize: 18
                                        color: Theme.accent
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: sectionRoot.modelData.title
                                        color: Theme.text
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 2
                                        radius: 1
                                        color: Qt.alpha(Theme.accent2, 0.64)
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: sectionRoot.modelData.items
                                    spacing: 6
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    delegate: Rectangle {
                                        id: rowRoot

                                        required property var modelData

                                        width: ListView.view.width
                                        height: 54
                                        radius: 5
                                        color: rowMouse.containsMouse ? Qt.alpha(Theme.accent, 0.10) : Qt.alpha(Theme.base, Theme.darkMode ? 0.30 : 0.42)
                                        border.width: 1
                                        border.color: rowMouse.containsMouse ? Qt.alpha(Theme.accent, 0.24) : Qt.alpha(Theme.text, 0.06)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            Flow {
                                                Layout.preferredWidth: Math.min(178, Math.max(116, rowRoot.width * 0.34))
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 5

                                                Repeater {
                                                    model: rowRoot.modelData.keys

                                                    Rectangle {
                                                        required property var modelData

                                                        width: Math.max(30, keyText.implicitWidth + 14)
                                                        height: 22
                                                        radius: 4
                                                        color: Qt.alpha(Theme.accent, 0.14)
                                                        border.width: 1
                                                        border.color: Qt.alpha(Theme.accent, 0.30)

                                                        Text {
                                                            id: keyText

                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            color: Theme.text
                                                            font.pixelSize: 11
                                                            font.weight: Font.DemiBold
                                                        }
                                                    }
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: rowRoot.modelData.title
                                                    color: Theme.text
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: rowRoot.modelData.description
                                                    color: Theme.subtext
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: rowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.NoButton
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.hotkeys.close();
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
        }
    }
}
