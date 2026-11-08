import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.ai

// The AI pet on the desktop: a Nothing slab with two dot-matrix eyes (AiFace)
// that sits on the wallpaper (WlrLayer.Background, like the other desktop
// widgets) and, when clicked, opens the same AiChatPanel the drawer shows,
// right there on the desktop (WlrLayer.Top while open, so it floats over your
// windows). The eyes follow the pointer, the slab reacts to what the AI says,
// and a bubble in Ndot 55 repeats its last words.
//
// Drag it anywhere: the spot is remembered in ~/.config/ndotshell/ai.json
// (AiService.orbX / orbY). Settings -> IA turns it on and off.
//
// The window is as tall as the face plus its bubble zone; the bubble lives in
// the upper part and is visual only — the input mask covers just the slab, so
// clicks over the bubble fall through to the wallpaper.
PanelWindow {
    id: win

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    readonly property real panelW: 420 * win.uiScale
    readonly property real panelH: 560 * win.uiScale
    readonly property real edge: 24 * win.uiScale

    readonly property real screenW: screen ? screen.width : 1920
    readonly property real screenH: screen ? screen.height : 1080

    readonly property real faceW: faceItem.contentW
    readonly property real faceH: faceItem.contentH

    // Where the pet wants to be (real pixels, the window's top-left). Never
    // saved yet goes bottom-right, above where the dock usually is.
    property real posX: AiService.orbX >= 0 ? AiService.orbX : win.screenW - win.faceW - 40 * win.uiScale
    property real posY: AiService.orbY >= 0 ? AiService.orbY : win.screenH - win.faceH - 120 * win.uiScale

    // Opening the panel grows the window and slides it back inside the
    // monitor if the pet was near an edge.
    readonly property real winW: AiService.orbOpen ? win.panelW : win.faceW
    readonly property real winH: AiService.orbOpen ? win.panelH : win.faceH
    readonly property real maxX: Math.max(0, win.screenW - win.winW - win.edge)
    readonly property real maxY: Math.max(0, win.screenH - win.winH - win.edge)
    readonly property real shownX: Math.max(win.edge, Math.min(win.posX, win.maxX))
    readonly property real shownY: Math.max(win.edge, Math.min(win.posY, win.maxY))

    // `screen !== null` used to sit in `visible` too: the window detaching
    // from the screen while hidden re-fed the binding and Qt reported a
    // loop. The pet does not need that guard (with no screens Quickshell
    // picks a default), so `visible` only reads the setting.
    visible: AiService.orbVisible
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

    mask: Region { item: inputBox }

    // ===== expanded: the chat =====
    AiChatPanel {
        anchors.fill: parent
        visible: AiService.orbOpen
        active: AiService.orbOpen
        showClose: true
        onCloseRequested: AiService.orbOpen = false
    }

    // ===== collapsed: the face =====
    AiFace {
        id: faceItem
        anchors.fill: parent
        visible: !AiService.orbOpen
        mt: win.mt
        uiScale: win.uiScale
        hasPointer: mouse.containsMouse && !drag.active
        pointerX: mouse.mouseX
        pointerY: mouse.mouseY
        dragging: drag.active
    }

    // Click-through everywhere but the slab; the bubble is a visual only.
    Item {
        id: inputBox
        x: 0
        y: AiService.orbOpen ? 0 : win.height - faceItem.faceH
        width: win.width
        height: AiService.orbOpen ? win.height : faceItem.faceH
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            faceItem.poke()
            faceItem.pressed = true
        }
        onCanceled: {
            faceItem.poke()
            faceItem.pressed = false
        }
        onReleased: faceItem.pressed = false
        // A click (no drag) opens the chat; a drag moves the pet.
        onClicked: AiService.orbOpen = true
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
