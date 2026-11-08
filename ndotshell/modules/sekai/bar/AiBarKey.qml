import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The AI key on the bar: a small round key with the "spark" glyph. Click it
// and the chat drawer comes out from the right; when the model is writing,
// a red dot pulses on the corner, and while the drawer is open the key stays
// lit. Hovering says which provider/model is answering.
//
// It talks to AiService directly (the same brain the drawer, the settings
// page and the desktop orb use), so the bar needs no extra wiring: it is one
// more module in the layout, id "ai".
Item {
    id: root

    readonly property var mt: Theme.of(QsWindow.window)

    property string barPosition: "top"

    implicitWidth: mt.pillHeight
    implicitHeight: mt.pillHeight + mt.shadowOffset

    readonly property bool lit: AiService.drawerOpen
    readonly property bool working: AiService.busy

    Pill {
        id: pill
        anchors.fill: parent
        cornerRadius: mt.radiusBadge
        ringWidth: 8
        capKeepsFill: root.lit || root.working
        fillColor: (root.lit || root.working) ? mt.nbAccent : mt.surface
        pressed: area.pressed

        Behavior on fillColor {
            ColorAnimation { duration: 200 }
        }

        MaterialIcon {
            id: barIcon
            anchors.centerIn: parent
            name: root.working ? "sync" : "auto_awesome"
            size: 18
            fill: root.lit ? 1 : 0
            color: (root.lit || root.working) ? "#ffffff" : mt.ink

            RotationAnimator on rotation {
                running: root.working
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1200
                onRunningChanged: if (!running) barIcon.rotation = 0
            }
        }

        // A key that is asking for an answer: a tiny dot blinking.
        Rectangle {
            visible: root.working
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -2
            anchors.rightMargin: -2
            width: 8
            height: 8
            radius: 4
            color: "#ffffff"
            border.width: 1
            border.color: mt.nbAccent

            SequentialAnimation on opacity {
                running: root.working
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 460; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 460; easing.type: Easing.InOutQuad }
            }
        }
    }

    BarTip {
        shown: area.containsMouse && !root.working
        text: AiService.configured
            ? "IA · " + AiService.providerLabel + " · " + AiService.model
            : "IA · sin configurar (Ajustes → IA)"
        barPosition: root.barPosition
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AiService.toggle()
        onPressed: if (root.barPosition === "left" || root.barPosition === "right") AiService.open()
    }
}
