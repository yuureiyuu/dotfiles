import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Wayland
import "../../services"
import "../../components"

PanelWindow {
    id: root

    required property LauncherModel dataModel
    required property var launcher

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:applauncher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: launcher.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: launcher.close()
        }

        RectangularShadow {
            anchors.fill: launcherCard
            radius: launcherCard.radius
            blur: 16
            spread: 0
            offset: Qt.vector2d(0, 4)
            color: "#30000000"
            cached: true
        }

        Rectangle {
            id: launcherCard

            readonly property bool wallpaperMode: root.dataModel && root.dataModel.wallpaperMode
            property real wallpaperTransitionProgress: wallpaperMode ? 1 : 0
            property real shownBottomMargin: 48
            readonly property real hiddenBottomMargin: -height - 56
            width: Math.min(parent.width - 48, 640)
            height: wallpaperMode ? 236 : Math.min(parent.height * 0.72, 560)
            radius: 4
            color: Theme.base
            border.width: 1
            border.color: Theme.border
            clip: true

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: hiddenBottomMargin + (shownBottomMargin - hiddenBottomMargin) * launcher.revealProgress

            Behavior on height {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on wallpaperTransitionProgress {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            opacity: 0.15 + 0.85 * launcher.revealProgress

            function activateItem(item) {
                if (!item)
                    return;

                if (item.kind === "wallpaper")
                    dataModel.applyWallpaper(item.filePath);
                else
                    dataModel.launchApp(item.entry);

                launcher.close();
            }

            Rectangle {
                anchors.fill: parent
                radius: launcherCard.radius
                color: Theme.base
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: launcherCard.wallpaperMode ? 12 : 14

                Behavior on spacing {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                ListView {
                    id: resultsView

                    property real animatedPreferredHeight: launcherCard.wallpaperMode ? 120 : -1

                    Layout.fillWidth: true
                    Layout.fillHeight: !launcherCard.wallpaperMode
                    Layout.preferredHeight: animatedPreferredHeight
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: true
                    model: root.dataModel ? root.dataModel.filteredModel : []
                    orientation: launcherCard.wallpaperMode ? ListView.Horizontal : ListView.Vertical
                    opacity: launcherCard.wallpaperMode ? 0.92 + 0.08 * launcherCard.wallpaperTransitionProgress : 1
                    scale: launcherCard.wallpaperMode ? 0.985 + 0.015 * launcherCard.wallpaperTransitionProgress : 1

                    Behavior on animatedPreferredHeight {
                        enabled: launcherCard.wallpaperMode
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    delegate: Item {
                        id: itemRoot

                        required property var modelData
                        required property int index

                        Component.onCompleted: {
                            if (launcherCard.wallpaperMode && modelData.kind === "wallpaper")
                                root.dataModel.ensureThumbnail(modelData.filePath, modelData.name);
                        }

                        width: launcherCard.wallpaperMode ? 120 : resultsView.width
                        height: launcherCard.wallpaperMode ? 110 : 68

                        Behavior on width {
                            NumberAnimation {
                                duration: 170
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 170
                                easing.type: Easing.OutCubic
                            }
                        }

                        RectangularShadow {
                            visible: launcherCard.wallpaperMode
                            anchors.fill: itemSurface
                            radius: itemSurface.radius
                            blur: itemRoot.ListView.isCurrentItem ? 10 : 7
                            spread: 0
                            offset: Qt.vector2d(0, itemRoot.ListView.isCurrentItem ? 2 : 1)
                            color: itemRoot.ListView.isCurrentItem ? Qt.alpha(Theme.accent, 0.14) : "#18000000"
                            cached: true
                        }

                        Rectangle {
                            id: itemSurface

                            anchors.fill: parent
                            anchors.leftMargin: launcherCard.wallpaperMode ? 4 : 0
                            anchors.rightMargin: launcherCard.wallpaperMode ? 4 : 0
                            anchors.topMargin: launcherCard.wallpaperMode ? 2 : 1
                            anchors.bottomMargin: launcherCard.wallpaperMode ? 4 : 3
                            radius: launcherCard.wallpaperMode ? 4 : 3
                            color: "transparent"
                            border.width: 0
                        }

                        RowLayout {
                            visible: !launcherCard.wallpaperMode
                            anchors.fill: itemSurface
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 2
                                Layout.preferredHeight: 34
                                radius: 1
                                color: Theme.accent
                                opacity: itemRoot.ListView.isCurrentItem ? 0.72 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            Item {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 30
                                    asynchronous: true
                                    source: modelData.kind === "wallpaper" ? modelData.fileUrl : Quickshell.iconPath(modelData.icon || "application-x-executable", "image-missing")
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Theme.text
                                    font.pixelSize: 16
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.description
                                    color: Theme.subtext
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Column {
                            visible: launcherCard.wallpaperMode
                            anchors.fill: itemSurface
                            anchors.margins: 4
                            spacing: 6

                            Rectangle {
                                width: parent.width
                                height: 82
                                radius: 4
                                color: Qt.alpha(Theme.mantle, 0.22)
                                border.width: itemRoot.ListView.isCurrentItem ? 1 : 0
                                border.color: Theme.accent
                                clip: true

                                Image {
                                    id: wallpaperImage

                                    anchors.fill: parent
                                    source: root.dataModel.thumbnailMap[modelData.filePath] || ""
                                    opacity: status === Image.Ready ? 1 : 0
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: 320
                                    sourceSize.height: 180
                                    mipmap: true

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: modelData.name.replace(/\.[^/.]+$/, "")
                                color: Theme.text
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: resultsView.currentIndex = index
                            onClicked: launcherCard.activateItem(modelData)
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    Layout.bottomMargin: launcherCard.wallpaperMode ? 6 : 0
                    radius: 4
                    color: Theme.mantle
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
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
                            placeholderText: SettingsService.t("Search apps or :wal")
                            placeholderTextColor: Theme.subtext
                            background: Item {}
                            selectByMouse: true
                            text: root.dataModel ? root.dataModel.query : ""

                            onTextChanged: {
                                if (!root.dataModel)
                                    return;

                                root.dataModel.query = text;
                                resultsView.currentIndex = root.dataModel.filteredModel.length > 0 ? 0 : -1;
                            }

                            onAccepted: {
                                if (root.dataModel && resultsView.currentIndex >= 0 && resultsView.currentIndex < root.dataModel.filteredModel.length)
                                    launcherCard.activateItem(root.dataModel.filteredModel[resultsView.currentIndex]);
                            }

                            Keys.onEscapePressed: launcher.close()
                            Keys.onDownPressed: {
                                if (root.dataModel && root.dataModel.filteredModel.length > 0)
                                    resultsView.currentIndex = Math.min(resultsView.currentIndex + 1, root.dataModel.filteredModel.length - 1);
                            }
                            Keys.onUpPressed: {
                                if (root.dataModel && root.dataModel.filteredModel.length > 0)
                                    resultsView.currentIndex = Math.max(resultsView.currentIndex - 1, 0);
                            }

                            Component.onCompleted: forceActiveFocus()
                        }

                        Rectangle {
                            visible: searchField.text.length > 0
                            width: 24
                            height: 24
                            radius: 0
                            color: clearMouseArea.containsMouse ? Theme.surface : "transparent"

                            LucideIcon {
                                anchors.centerIn: parent
                                icon: Icons.circleX
                                iconSize: 15
                                color: Theme.icon
                            }

                            MouseArea {
                                id: clearMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: searchField.clear()
                            }
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    launcher.close();
                    event.accepted = true;
                }
            }

            Connections {
                target: root.dataModel

                function onFilteredModelChanged() {
                    resultsView.currentIndex = root.dataModel && root.dataModel.filteredModel.length > 0 ? 0 : -1;
                }
            }

            Component.onCompleted: {
                if (root.dataModel) {
                    root.dataModel.query = "";
                    resultsView.currentIndex = root.dataModel.filteredModel.length > 0 ? 0 : -1;
                }
                searchField.forceActiveFocus();
            }
        }
    }
}
