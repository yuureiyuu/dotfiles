import QtQuick
import "../../services"
import "../../utils"

Item {
    id: root

    width: implicitWidth
    implicitWidth: horizontal ? (root.hovered ? 48 : 25) : 25
    height: implicitHeight
    implicitHeight: 25
    visible: SettingsService.batteryService
    clip: false
    property bool horizontal: false
    readonly property int animationDuration: SettingsService.duration(360)
    readonly property int verticalRevealOffset: 24
    readonly property bool hovered: batteryMouse.containsMouse

    readonly property int percent: {
        if (Config.useRealBattery && Battery.available)
            return Math.round(Battery.percentage * 100);
        if (!Config.useRealBattery)
            return 100;
        return 0;
    }
    readonly property int bars: percent >= 70 ? 3 : (percent >= 40 ? 2 : (percent > 10 ? 1 : 0))
    readonly property color outlineColor: percent <= 10 && Config.useRealBattery ? "#f38ba8" : Theme.barIcon
    readonly property color fillColor: percent <= 10 && Config.useRealBattery ? "#f38ba8" : (Battery.isCharging ? Theme.barIconActive : Theme.mixColor(Theme.accent, Theme.barIcon, 0.42))

    Behavior on implicitWidth {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: batteryLayer

        width: 22
        height: 22
        x: root.horizontal ? (root.hovered ? 0 : 1.5) : (parent.width / 2 - width / 2 + 1.5)
        y: root.horizontal ? 1 : (root.hovered ? -root.verticalRevealOffset : 1)
        opacity: root.hovered ? 0.9 : 1

        Behavior on x {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: SettingsService.duration(280)
                easing.type: Easing.OutCubic
            }
        }

        Item {
            anchors.centerIn: parent
            width: 25
            height: 17

            Rectangle {
                x: 0
                y: 2
                width: 21
                height: 13
                radius: 2.5
                color: "transparent"
                border.width: 1.8
                border.color: root.outlineColor
            }

            Rectangle {
                x: 22
                y: 6
                width: 3
                height: 5
                radius: 1
                color: root.outlineColor
            }

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    x: 3.5 + index * 5.7
                    y: 6
                    width: 3.4
                    height: 5
                    radius: 1
                    color: index < root.bars ? root.fillColor : "transparent"
                    opacity: index < root.bars ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: SettingsService.duration(140)
                        }
                    }
                }
            }
        }
    }

    Text {
        id: percentLabel

        width: parent.width
        height: parent.height
        x: root.horizontal ? (root.hovered ? 24 : 0) : 0
        y: root.horizontal ? 0 : (root.hovered ? 0 : -root.verticalRevealOffset)
        opacity: root.hovered ? 1 : 0
        text: root.percent
        color: Theme.barIcon
        font.pixelSize: 16
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on x {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.hovered ? SettingsService.duration(260) : SettingsService.duration(150)
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: batteryMouse

        x: -3
        y: root.horizontal ? -3 : -root.verticalRevealOffset - 3
        width: parent.width + 6
        height: parent.height + (root.horizontal ? 6 : root.verticalRevealOffset + 6)
        hoverEnabled: true
    }
}
