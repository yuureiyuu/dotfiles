pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../components"
import "../../services"

Item {
    id: root
    width: horizontal ? Math.max(root.trayIconCellSize, root.trayItemsWidth + root.trayIconSpacing + root.trayIconCellSize) : 40
    height: horizontal ? 24 : verticalTrayContent.implicitHeight

    property bool horizontal: false
    property string side: "right"
    property Item menuParent: null
    property bool isOpen: true
    property bool menuOpen: false
    property var activeTrayItem: null
    property Item activeTrayIcon: null
    readonly property int menuWidth: 286
    readonly property int menuHeight: 286
    readonly property int menuPadding: 0
    readonly property int openMenuWidth: menuOpen ? menuWidth + menuPadding : 0
    readonly property int visibleMenuWidth: trayMenuHost.width
    readonly property int trayIconCellSize: 24
    readonly property int trayIconVisualSize: 26
    readonly property int trayIconSpacing: 6
    readonly property int trayItemCount: SystemTray.items?.values?.length ?? SystemTray.items?.length ?? 0
    readonly property int trayItemsWidth: trayItemCount > 0 ? trayItemCount * trayIconCellSize + (trayItemCount - 1) * trayIconSpacing : 0
    property alias menuInputRegion: trayMenuHost

    function desktopIconForTrayItem(item, icon) {
        const rawCandidates = [
            item?.id ?? "",
            item?.title ?? "",
            icon ?? "",
            (icon ?? "").replace(/-(tray|symbolic|status|panel|mute|muted|dark|light)$/i, ""),
            (icon ?? "").replace(/-(tray|symbolic)$/i, "").replace(/-(mute|muted)$/i, "")
        ];

        for (const raw of rawCandidates) {
            const candidate = String(raw).trim();
            if (!candidate.length)
                continue;

            const desktopEntry = DesktopEntries.heuristicLookup(candidate);
            if (desktopEntry?.icon)
                return desktopEntry.icon;
        }

        const normalizedCandidates = rawCandidates.map(raw => String(raw).trim().toLowerCase().replace(/\.desktop$/i, ""));
        for (const app of DesktopEntries.applications.values) {
            const appId = String(app.id ?? "").toLowerCase().replace(/\.desktop$/i, "");
            const appName = String(app.name ?? "").toLowerCase();
            if (normalizedCandidates.some(candidate => candidate.length > 0 && (appId.includes(candidate) || appName.includes(candidate))))
                return app.icon;
        }

        return "";
    }

    function trayIconSource(item) {
        let icon = item?.icon ?? "";
        if (icon.includes("?path=")) {
            const parts = icon.split("?path=");
            const name = parts[0];
            const path = parts[1];
            return Qt.resolvedUrl(`${path}/${name.slice(name.lastIndexOf("/") + 1)}`);
        }

        const desktopIcon = root.desktopIconForTrayItem(item, icon);
        if (desktopIcon.length > 0 && (icon.length === 0 || icon.endsWith("-tray") || icon.endsWith("-symbolic") || icon.includes("-mute")))
            return Quickshell.iconPath(desktopIcon, icon);

        return icon;
    }

    function closeMenu() {
        menuOpen = false;
        activeTrayItem = null;
        activeTrayIcon = null;
        trayMenuStack.clear();
    }

    function openMenu(item, iconItem) {
        if (!item || !item.menu) {
            closeMenu();
            return;
        }

        activeTrayItem = item;
        activeTrayIcon = iconItem;
        trayMenuStack.clear();
        trayMenuStack.push(menuPageComponent, {
            menuHandle: item.menu,
            isSubMenu: false
        });
        menuOpen = true;
    }

    function toggleMenu(item, iconItem) {
        if (menuOpen && activeTrayItem === item) {
            closeMenu();
            return;
        }

        openMenu(item, iconItem);
    }

    component TrayIconDelegate: Item {
        id: trayCell

        required property var modelData
        property bool horizontalCell: false

        Layout.alignment: horizontalCell ? Qt.AlignVCenter : Qt.AlignHCenter
        Layout.preferredWidth: root.trayIconCellSize
        Layout.preferredHeight: root.trayIconCellSize
        implicitWidth: root.trayIconCellSize
        implicitHeight: root.trayIconCellSize
        clip: true

        IconImage {
            id: trayIconImage

            anchors.centerIn: parent
            width: root.trayIconVisualSize
            height: root.trayIconVisualSize
            implicitSize: root.trayIconVisualSize
            source: root.trayIconSource(trayCell.modelData)
            asynchronous: true
            opacity: trayMouse.containsMouse ? 1.0 : 0.88
        }

        MouseArea {
            id: trayMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: event => {
                if (event.button === Qt.LeftButton) {
                    if (trayCell.modelData.menu)
                        root.toggleMenu(trayCell.modelData, trayCell);
                    else
                        trayCell.modelData.activate();
                } else {
                    root.closeMenu();
                    trayCell.modelData.activate();
                }
            }
        }
    }

    ColumnLayout {
        id: verticalTrayContent

        visible: !root.horizontal
        anchors.centerIn: parent
        width: 40
        spacing: 9

        Item {
        id: trayListViewport

        property real animatedSize: root.isOpen ? (root.horizontal ? root.trayItemsWidth : trayList.implicitHeight) : 0

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.horizontal ? animatedSize : root.trayIconCellSize
        Layout.preferredHeight: root.horizontal ? root.trayIconCellSize : animatedSize
        clip: true

        Behavior on animatedSize {
            NumberAnimation {
                duration: SettingsService.duration(210)
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: trayList

            visible: !root.horizontal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: root.trayIconSpacing
            opacity: root.isOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: SettingsService.duration(140)
                }
            }

            Repeater {
                model: SystemTray.items

                delegate: TrayIconDelegate {
                    horizontalCell: false
                }
            }
        }

        }

        ThemedSvgIcon {
            id: verticalToggleIcon
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            iconSize: 23
            iconName: root.isOpen ? "eye" : "eye-off"
            color: verticalToggleMouse.containsMouse ? Theme.barIconActive : Theme.barIcon
            opacity: 1.0

            MouseArea {
                id: verticalToggleMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.closeMenu();
                    root.isOpen = !root.isOpen;
                }
            }
        }
    }

    Item {
        id: horizontalTrayContent

        visible: root.horizontal
        anchors.fill: parent

        Item {
            id: horizontalTrayViewport

            width: root.isOpen ? root.trayItemsWidth : 0
            height: root.trayIconCellSize
            anchors {
                right: horizontalToggleIcon.left
                rightMargin: root.trayIconSpacing
                verticalCenter: parent.verticalCenter
            }
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: SettingsService.duration(210)
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                id: trayRow

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: root.trayIconSpacing
                opacity: root.isOpen ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: SettingsService.duration(140)
                    }
                }

                Repeater {
                    model: SystemTray.items

                    delegate: TrayIconDelegate {
                        horizontalCell: true
                    }
                }
            }
        }

        ThemedSvgIcon {
            id: horizontalToggleIcon

            width: 24
            height: 24
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            iconSize: 23
            iconName: root.isOpen ? "eye" : "eye-off"
            color: horizontalToggleMouse.containsMouse ? Theme.barIconActive : Theme.barIcon
            opacity: 1.0

            MouseArea {
                id: horizontalToggleMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.closeMenu();
                    root.isOpen = !root.isOpen;
                }
            }
        }
    }

    Item {
        id: trayMenuHost

        parent: root.menuParent ? root.menuParent : root.parent
        visible: root.menuOpen || menuSlideAnimation.running || menuFadeAnimation.running
        clip: true
        width: root.menuWidth
        height: Math.min(trayMenuPanel.implicitHeight, 420)
        x: {
            if (root.side === "left")
                return 69 + root.menuPadding;
            if (root.side === "top") {
                const iconCenter = root.activeTrayIcon ? root.activeTrayIcon.mapToItem(trayMenuHost.parent, root.activeTrayIcon.width / 2, 0).x : root.mapToItem(trayMenuHost.parent, root.width / 2, 0).x;
                return Math.max(8, Math.min(trayMenuHost.parent.width - width - 8, iconCenter - width / 2));
            }
            return parent.width - 69 - root.menuWidth - root.menuPadding;
        }
        y: {
            if (root.side === "top")
                return 58 + root.menuPadding;
            const iconCenter = root.activeTrayIcon ? root.activeTrayIcon.mapToItem(trayMenuHost.parent, 0, root.activeTrayIcon.height / 2).y : root.mapToItem(trayMenuHost.parent, 0, root.height / 2).y;
            return Math.max(8, Math.min(trayMenuHost.parent.height - height - 8, iconCenter - height / 2));
        }
        z: 50

        Behavior on x {
            NumberAnimation {
                duration: SettingsService.duration(220)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: SettingsService.duration(220)
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: trayMenuPanel

            x: {
                if (root.side === "left")
                    return root.menuOpen ? 0 : -root.menuWidth;
                if (root.side === "top")
                    return 0;
                return root.menuOpen ? 0 : root.menuWidth;
            }
            y: root.side === "top" ? (root.menuOpen ? 0 : -height) : 0
            opacity: root.menuOpen ? 1 : 0
            width: root.menuWidth
            implicitHeight: trayMenuStack.implicitHeight + 18
            height: implicitHeight
            radius: 12
            color: Qt.alpha(Theme.mantle, 0.94)
            border.width: 0

            Behavior on x {
                NumberAnimation {
                    id: menuSlideAnimation
                    duration: SettingsService.duration(220)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: SettingsService.duration(220)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    id: menuFadeAnimation
                    duration: SettingsService.duration(140)
                    easing.type: Easing.OutCubic
                }
            }

            StackView {
                id: trayMenuStack

                anchors {
                    fill: parent
                    margins: 9
                }
                implicitWidth: currentItem?.implicitWidth ?? root.menuWidth - 18
                implicitHeight: currentItem?.implicitHeight ?? 0
                clip: true

                pushEnter: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: SettingsService.duration(110)
                    }
                }
                pushExit: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: SettingsService.duration(80)
                    }
                }
                popEnter: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: SettingsService.duration(110)
                    }
                }
                popExit: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: SettingsService.duration(80)
                    }
                }
            }
        }
    }

    Component {
        id: menuPageComponent

        ColumnLayout {
            id: menuPage

            required property var menuHandle
            property bool isSubMenu: false

            width: root.menuWidth - 18
            spacing: 4

            QsMenuOpener {
                id: menuOpener

                menu: menuPage.menuHandle
            }

            Repeater {
                model: menuOpener.children

                delegate: Item {
                    id: menuEntry

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.isSeparator ? 1 : 30

                    Rectangle {
                        visible: menuEntry.modelData.isSeparator
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: 1
                        color: Qt.alpha(Theme.border, 0.55)
                    }

                    Rectangle {
                        visible: !menuEntry.modelData.isSeparator
                        anchors.fill: parent
                        radius: 4
                        color: menuMouse.containsMouse ? Qt.alpha(Theme.surface2, 0.78) : "transparent"
                    }

                    IconImage {
                        id: entryIcon

                        visible: !menuEntry.modelData.isSeparator && menuEntry.modelData.icon !== ""
                        anchors {
                            left: parent.left
                            leftMargin: 7
                            verticalCenter: parent.verticalCenter
                        }
                        implicitSize: 18
                        source: menuEntry.modelData.icon
                        opacity: menuEntry.modelData.enabled ? 0.92 : 0.38
                    }

                    Text {
                        visible: !menuEntry.modelData.isSeparator
                        anchors {
                            left: entryIcon.visible ? entryIcon.right : parent.left
                            leftMargin: entryIcon.visible ? 8 : 8
                            right: submenuChevron.visible ? submenuChevron.left : parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        text: menuEntry.modelData.text
                        color: menuEntry.modelData.enabled ? Theme.text : Theme.subtext
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    LucideIcon {
                        id: submenuChevron

                        visible: !menuEntry.modelData.isSeparator && menuEntry.modelData.hasChildren
                        anchors {
                            right: parent.right
                            rightMargin: 7
                            verticalCenter: parent.verticalCenter
                        }
                        icon: Icons.chevronRight
                        iconSize: 16
                        color: menuEntry.modelData.enabled ? Theme.icon : Theme.iconMuted
                    }

                    MouseArea {
                        id: menuMouse

                        visible: !menuEntry.modelData.isSeparator
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: menuEntry.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        hoverEnabled: true
                        enabled: menuEntry.modelData.enabled
                        onClicked: {
                            if (menuEntry.modelData.hasChildren)
                                trayMenuStack.push(menuPageComponent, {
                                    menuHandle: menuEntry.modelData,
                                    isSubMenu: true
                                });
                            else {
                                menuEntry.modelData.triggered();
                                root.closeMenu();
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                visible: menuPage.isSubMenu

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: backMouse.containsMouse ? Qt.alpha(Theme.surface2, 0.78) : Qt.alpha(Theme.surface, 0.55)
                }

                LucideIcon {
                    id: backIcon

                    anchors {
                        left: parent.left
                        leftMargin: 7
                        verticalCenter: parent.verticalCenter
                    }
                    icon: Icons.chevronLeft
                    iconSize: 16
                    color: Theme.icon
                }

                Text {
                    anchors {
                        left: backIcon.right
                        leftMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: SettingsService.t("Back")
                    color: Theme.text
                    font.pixelSize: 13
                }

                MouseArea {
                    id: backMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: trayMenuStack.pop()
                }
            }
        }
    }
}
