import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.ai

// The AI orb on the desktop: a small Nothing-style circle that sits on the
// wallpaper (WlrLayer.Background, like the other desktop widgets) and, when
// clicked, opens the same AiChatPanel the drawer shows, right there on the
// desktop (WlrLayer.Top while open, so it floats over your windows).
//
// Drag it anywhere: the spot is remembered in ~/.config/ndotshell/ai.json
// (AiService.orbX / orbY). Settings -> IA turns it on and off.
PanelWindow {
    id: win

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    readonly property real orbSize: 64 * win.uiScale
    readonly property real panelW: 420 * win.uiScale
    readonly property real panelH: 560 * win.uiScale
    readonly property real edge: 24 * win.uiScale

    readonly property real screenW: screen ? screen.width : 1920
    readonly property real screenH: screen ? screen.height : 1080

    // Where the orb wants to be (real pixels). A spot never saved yet goes
    // bottom-right, above where the dock usually is.
    property real posX: AiService.orbX >= 0 ? AiService.orbX : win.screenW - win.orbSize - 40 * win.uiScale
    property real posY: AiService.orbY >= 0 ? AiService.orbY : win.screenH - win.orbSize - 150 * win.uiScale

    // The window is only as big as what it draws. Opening the panel grows it
    // and slides it back inside the monitor if the orb was near an edge.
    readonly property real winW: AiService.orbOpen ? win.panelW : win.orbSize
    readonly property real winH: AiService.orbOpen ? win.panelH : win.orbSize
    readonly property real maxX: Math.max(0, win.screenW - win.winW - win.edge)
    readonly property real maxY: Math.max(0, win.screenH - win.winH - win.edge)
    readonly property real shownX: Math.max(win.edge, Math.min(win.posX, win.maxX))
    readonly property real shownY: Math.max(win.edge, Math.min(win.posY, win.maxY))

    visible: AiService.orbVisible && screen !== null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
    }

    margins {
        left: Math.round(win.shownX)
        top: Math.round(win.shownY)
    }

    implicitWidth: Math.round(win.winW)
    implicitHeight: Math.round(win.winH)

    WlrLayershell.layer: AiService.orbOpen ? WlrLayer.Top : WlrLayer.Background
    WlrLayershell.namespace: "ndotshell-ai-orb"
    WlrLayershell.keyboardFocus: AiService.orbOpen
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // ===== expanded: the chat =====
    AiChatPanel {
        anchors.fill: parent
        visible: AiService.orbOpen
        active: AiService.orbOpen
        showClose: true
        onCloseRequested: AiService.orbOpen = false
    }

    // ===== collapsed: the orb =====
    Item {
        id: orb
        anchors.fill: parent
        visible: !AiService.orbOpen

        Rectangle {
            id: halo
            anchors.centerIn: parent
            width: parent.width + 18 * win.uiScale
            height: width
            radius: width / 2
            color: win.mt.nbAccent
            opacity: AiService.busy ? 0.20 : 0.10

            SequentialAnimation on opacity {
                running: AiService.busy
                loops: Animation.Infinite
                NumberAnimation { to: 0.34; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.12; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: win.mt.nbSurface
            border.width: 1
            border.color: mouse.containsMouse ? win.mt.nbAccent : win.mt.nbBorder

            Behavior on border.color { ColorAnimation { duration: 140 } }

            MaterialIcon {
                id: orbIcon
                anchors.centerIn: parent
                name: AiService.busy ? "sync" : "auto_awesome"
                size: 24 * win.uiScale
                color: AiService.busy ? win.mt.nbAccent : win.mt.nbInk

                RotationAnimator on rotation {
                    running: AiService.busy
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1200
                    onRunningChanged: if (!running) orbIcon.rotation = 0
                }
            }

            // The Nothing dot: red while the model writes.
            Rectangle {
                visible: AiService.busy
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8 * win.uiScale
                anchors.rightMargin: 8 * win.uiScale
                width: 7 * win.uiScale
                height: width
                radius: width / 2
                color: win.mt.nbAccent
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: AiService.orbOpen = true
        }

        DragHandler {
            id: drag
            target: null
            property real lastX: 0
            property real lastY: 0
            onActiveChanged: {
                if (active) {
                    drag.lastX = 0
                    drag.lastY = 0
                    win.posX = win.shownX
                    win.posY = win.shownY
                } else {
                    AiService.setOrbPos(Math.round(win.posX), Math.round(win.posY))
                }
            }
            onActiveTranslationChanged: {
                if (!drag.active) return
                const dx = drag.activeTranslation.x - drag.lastX
                const dy = drag.activeTranslation.y - drag.lastY
                drag.lastX = drag.activeTranslation.x
                drag.lastY = drag.activeTranslation.y
                win.posX = Math.max(0, Math.min(win.maxX, win.posX + dx))
                win.posY = Math.max(0, Math.min(win.maxY, win.posY + dy))
            }
        }
    }
}
