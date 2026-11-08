import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

// One of the AI panel's round keys (copy, clear, close). A ghost circle that
// only shows its outline on hover, Nothing style.
Rectangle {
    id: root

    property string icon: ""
    property string tip: ""
    property bool danger: false
    signal clicked()

    readonly property var mt: Theme.of(QsWindow.window)

    width: 30
    height: 30
    radius: 15
    color: mouse.containsMouse ? mt.nbRaised : "transparent"
    border.width: 1
    border.color: mouse.containsMouse ? mt.nbBorder : "transparent"

    MaterialIcon {
        anchors.centerIn: parent
        name: root.icon
        size: 16
        color: root.danger ? mt.nbAccent : mt.nbInkSub
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
