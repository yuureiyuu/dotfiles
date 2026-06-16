import QtQuick

Item {
    id: root
    width: 35
    height: 38
    signal clicked

    Image {
        id: powerIcon
        source: "../../assets/ougi-session.png"
        anchors.centerIn: parent
        width: 35
        height: 38
        sourceSize.width: 96
        sourceSize.height: 110
        opacity: mouseArea.containsMouse ? 1.0 : 0.8
        smooth: true
        mipmap: true
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.clicked();
        }
    }
}
