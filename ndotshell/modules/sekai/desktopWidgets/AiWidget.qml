import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.ai
import qs.modules.sekai.editMode

// The desktop AI pet: the face card (modules/sekai/ai/AiFace.qml) — two
// little balls with feelings — as a real desktop widget, with the same drag,
// lock, scale, monitors, Edit Desktop and Focus Mode as the Now Playing
// card, the clock and the weather card. Type a question into the card and
// Enter sends it from the desktop itself; the reply streams right back into
// the card. A double click (on the card, not the field) opens the full chat
// drawer.
//
//   The card      the Pill housing, the header (red dot, THINKING / TYPING /
//                 ERROR / IDLE, dancing bars, provider), the dot-matrix eyes,
//                 the words in fontDisplay and the ask row.
//   The spot      remembered in AiWidgetService (state/aiwidget-state.sh),
//                 moved by dragging in Edit Desktop (or with Lock all off).
//
// Off with the shelf, Ajustes → IA, or:
//   qs -c ndotshell ipc call ai orb        (show / hide)
//
// How the moving works: exactly like NowPlayingWidget.qml. ONE transparent
// window with the card as an Item inside it. Dragging just moves that Item,
// so it stays smooth, and the window's input `mask` is only the card, so
// every click anywhere else passes straight through.
PanelWindow {
    id: win

    // This monitor's theme: Theme.of() gives the shell's own unless the monitor has one.
    readonly property var mt: Theme.of(screen)

    function resetPosition(): void {
        win.clearSpot()
        win.place()
        win.saveSpot(card.x, card.y)
    }

    // Which monitor it lives on, by name (`hyprctl monitors`), e.g. "DP-1".
    // Empty = the monitor the card was last dropped on (remembered in
    // AiWidgetService), or the first screen if it has never been moved.
    property string monitor: ""

    // A copy on another monitor (WidgetClones.qml): the same widget, with a spot
    // of its own. The main copy keeps its spot in the service as before.
    property bool clone: false

    readonly property var cloneSpot: win.clone ? WidgetClones.spot("aiwidget", win.wantedScreen) : null
    readonly property bool spotReady: win.clone ? (WidgetClones.loaded && win.cloneSpot !== null) : AiWidgetService.loaded
    readonly property real spotX: win.clone ? (win.cloneSpot ? win.cloneSpot.x : -1) : AiWidgetService.posX
    readonly property real spotY: win.clone ? (win.cloneSpot ? win.cloneSpot.y : -1) : AiWidgetService.posY
    readonly property real spotScale: win.clone ? (win.cloneSpot ? win.cloneSpot.scale : 0) : AiWidgetService.posScale

    function saveSpot(x, y): void {
        if (win.clone)
            WidgetClones.setSpot("aiwidget", win.wantedScreen, x, y, win.uiScale)
        else
            AiWidgetService.setPosition(x, y, win.uiScale)
    }

    function clearSpot(): void {
        if (win.clone) {
            WidgetClones.clearSpot("aiwidget", win.wantedScreen)
        } else {
            AiWidgetService.posX = -1
            AiWidgetService.posY = -1
        }
    }

    function fixSpotScale(): void {
        if (win.clone) {
            WidgetClones.setSpot("aiwidget", win.wantedScreen, win.spotX, win.spotY, win.uiScale)
        } else {
            AiWidgetService.posScale = win.uiScale
            AiWidgetService.persist()
        }
    }

    readonly property string wantedScreen: win.monitor !== "" ? win.monitor : AiWidgetService.screenName
    screen: Quickshell.screens.find(s => s.name === win.wantedScreen) ?? DesktopMonitors.fallbackScreen

    // This monitor's scale (scale.json / services/ShellScale.qml). The card is
    // drawn in design pixels inside a ScaleHost, so `roomW` x `roomH` is the
    // screen as the card sees it (real size / scale); positions are kept in
    // that same design space.
    readonly property real uiScale: ShellScale.forScreen(win.screen)
    readonly property real fullW: win.screen ? win.screen.width : 0
    readonly property real fullH: win.screen ? win.screen.height : 0
    readonly property real roomW: win.fullW / win.uiScale
    readonly property real roomH: win.fullH / win.uiScale

    // ===== a small window while nothing needs the whole screen =====
    readonly property bool compact: !EditMode.active && !win.gliding && EditMode.screenName === ""
        && EditMode.compactWindows && !EditMode.desktopDragAllowed && win.fullW > 0 && win.placed
    readonly property real boxPad: Math.ceil((0.16 * Math.max(card.width, card.height) + 24) * win.uiScale)
    readonly property real boxX: win.compact ? Math.max(0, Math.floor(card.x * win.uiScale - win.boxPad)) : 0
    readonly property real boxY: win.compact ? Math.max(0, Math.floor(card.y * win.uiScale - win.boxPad)) : 0
    readonly property real boxW: Math.max(1, Math.min(win.fullW,
        Math.ceil((card.x + card.width) * win.uiScale + win.boxPad)) - win.boxX)
    readonly property real boxH: Math.max(1, Math.min(win.fullH,
        Math.ceil((card.y + card.height) * win.uiScale + win.boxPad)) - win.boxY)

    // ===== the card's own size, in design pixels (AiFace.qml draws it) =====
    readonly property int cardWidth: 320
    readonly property int cardHeight: 204
    readonly property int pad: 18

    // ===== on / off =====
    FocusGate {
        id: gate
        widgetId: "aiwidget"
        screenName: win.screen ? win.screen.name : ""
    }

    readonly property bool switchedOn: AiWidgetService.loaded && AiWidgetService.shown
    readonly property bool want: win.switchedOn && gate.show
    property real reveal: 0

    // Off while the saved state is read back, so a reload doesn't replay the pop.
    property bool armed: false

    onWantChanged: {
        if (!win.armed) {
            popIn.stop()
            swallow.stop()
            win.reveal = win.want ? 1 : 0
        } else if (win.want) {
            swallow.stop()
            popIn.restart()
        } else {
            popIn.stop()
            swallow.restart()
        }
    }

    NumberAnimation {
        id: popIn
        target: win
        property: "reveal"
        to: 1
        duration: 460
        easing.type: Easing.OutBack
        easing.overshoot: 1.9
    }

    NumberAnimation {
        id: swallow
        target: win
        property: "reveal"
        to: 0
        duration: 300
        easing.type: Easing.InCubic
    }

    Timer {
        interval: 800
        running: AiWidgetService.loaded
        onTriggered: win.armed = true
    }

    property bool placed: false

    // `live`: the card is on, or still being swallowed.
    readonly property bool live: win.want || win.reveal > 0.001

    // Not mapped while the widget is off: a full-screen transparent layer that is
    // only sitting there still costs the compositor a blend on every frame.
    visible: AiWidgetService.loaded && (win.live || EditMode.active)

    // Always BELOW the dock: the widgets rest on Background (mapped after the
    // wallpaper, so over it) and the dock is on Bottom or Top, so the dock is never
    // behind a widget. Up a layer while this widget is edited or moved
    // (EditChrome.raised), so the one edited last is in front of the other widgets.
    WlrLayershell.layer: (chrome.raised || WallpaperService.restacking) ? WlrLayer.Bottom : WlrLayer.Background
    WlrLayershell.namespace: "ndotshell-ai-widget"
    // The ask field types here, so the card may take the keyboard on a click.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        top: true
        left: true
        right: !win.compact
        bottom: !win.compact
    }

    margins {
        left: win.boxX
        top: win.boxY
    }

    implicitWidth: win.boxW
    implicitHeight: win.boxH

    // Only the card takes clicks; the rest of the screen falls through.
    mask: Region { item: cardMask }

    Item {
        id: cardMask
        readonly property real m: stage.editing ? 38 : 0
        readonly property real k: win.uiScale * stage.scale
        readonly property real x1: shifter.x + stage.x + (card.x + card.width + m) * k
        readonly property real y1: shifter.y + stage.y + (card.y + card.height + m) * k
        x: !win.live ? 0 : Math.max(0, Math.round(shifter.x + stage.x + (card.x - m) * k))
        y: !win.live ? 0 : Math.max(0, Math.round(shifter.y + stage.y + (card.y - m) * k))
        width: !win.live ? 1 : Math.max(0, Math.ceil(x1) - x)
        height: !win.live ? 1 : Math.max(0, Math.ceil(y1) - y)
    }

    // ===== placement =====
    function place(): void {
        if (win.roomW <= 0 || win.roomH <= 0)
            return
        let x = win.spotX
        let y = win.spotY
        if (x < 0 || y < 0) {
            // A new pet rests in the bottom-right corner, above the dock, where
            // the old orb used to sit.
            x = Math.round(win.roomW - card.width - 24)
            y = Math.round(win.roomH - card.height - 120)
        } else if (win.spotScale > 0 && win.uiScale > 0) {
            // Saved at another shell scale: same spot on the screen, not the same
            // design pixels (the card keeps its top-left corner).
            const k = win.spotScale / win.uiScale
            x *= k
            y *= k
        }
        card.x = Math.max(0, Math.min(x, win.roomW - card.width))
        card.y = Math.max(0, Math.min(y, win.roomH - card.height))
        win.placed = true
    }

    // After a reload the window, the monitor list and scale.json all settle over a
    // few frames; place again once they have, so the card always ends on its saved
    // spot (never while it is being dragged).
    Timer {
        id: settle
        interval: 300
        onTriggered: {
            if (win.spotReady && win.spotX >= 0 && win.spotScale <= 0 && !dragArea.drag.active) {
                win.fixSpotScale()
            }
            if (!chrome.dragging && !dragArea.drag.active)
                win.place()
        }
    }

    onWidthChanged: { Qt.callLater(win.place); settle.restart() }
    onHeightChanged: { Qt.callLater(win.place); settle.restart() }
    onUiScaleChanged: { win.place(); settle.restart() }
    onScreenChanged: { win.place(); settle.restart() }
    onVisibleChanged: settle.restart()
    Component.onCompleted: {
        win.reveal = win.want ? 1 : 0
        win.place()
    }

    Connections {
        target: AiWidgetService
        function onLoadedChanged() {
            win.place()
            settle.restart()
        }
        // A desktop preset hands the service another saved spot while the card is
        // on screen. The spot arrives as several properties one after the other, so
        // wait a beat and place once.
        function onPosXChanged() { follow.restart() }
        function onPosYChanged() { follow.restart() }
        function onPosScaleChanged() { follow.restart() }
    }

    // A preset hands the card another spot: it glides there instead of jumping
    // (not while it is being dragged, and not when it is already where it should be).
    property bool gliding: false
    property bool glideOn: false

    Timer {
        id: follow
        interval: 16
        onTriggered: {
            if (chrome.dragging || dragArea.drag.active)
                return
            const ox = card.x
            const oy = card.y
            win.place()
            if (Math.abs(card.x - ox) + Math.abs(card.y - oy) < 2)
                return
            card.x = ox
            card.y = oy
            win.gliding = true
            glideStart.restart()
        }
    }

    Timer {
        id: glideStart
        interval: 80
        onTriggered: {
            win.glideOn = true
            win.place()
            glideEnd.restart()
        }
    }

    Timer {
        id: glideEnd
        interval: 640
        onTriggered: {
            win.glideOn = false
            win.gliding = false
        }
    }

    // Edit Desktop's shelf shows the card as it really looks (EditPreview.qml).
    EditPreview {
        widgetId: "aiwidget"
        target: card
        pixelRatio: win.uiScale
    }

    // ===== the desktop =====
    Item {
        id: shifter
        x: -win.boxX
        y: -win.boxY
        width: win.fullW
        height: win.fullH

        EditStage {
            id: stage
            screenObj: win.screen
            uiScale: win.uiScale

            ScaleHost {
                anchors.fill: parent
                factor: win.uiScale

                Item {
                    id: card

                    Behavior on x {
                        enabled: win.glideOn
                        NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
                    }
                    Behavior on y {
                        enabled: win.glideOn
                        NumberAnimation { duration: 520; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
                    }

                    width: win.cardWidth
                    height: win.cardHeight
                    scale: Math.max(0, win.reveal)
                    opacity: Math.max(0, Math.min(1, win.reveal))
                    transformOrigin: Item.Center

                    // Edit Desktop: outline, corner diamonds, a tag and a drag
                    // shield. Above the content in z (z: 1), but disabled until
                    // the card is selected or the desktop is unlocked, so on the
                    // normal desktop the card body falls through to the pet.
                    MouseArea {
                        id: dragArea
                        enabled: EditMode.desktopDragAllowed || chrome.selected
                        z: 1
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: EditMode.desktopDragAllowed || chrome.selected
                            ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor

                        drag.target: EditMode.desktopDragAllowed || chrome.selected ? card : null
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.maximumX: Math.max(0, win.roomW - card.width)
                        drag.minimumY: 0
                        drag.maximumY: Math.max(0, win.roomH - card.height)

                        drag.onActiveChanged: {
                            chrome.ownDrag = drag.active
                            if (!drag.active)
                                win.saveSpot(card.x, card.y)
                        }
                    }

                    // The pet: the whole card reacts while the widget is not
                    // being edited — the eyes follow the pointer, a press
                    // startles it, a double click opens the chat drawer. The
                    // ask field lives inside the face, above this area, and
                    // wins its own clicks.
                    MouseArea {
                        id: petArea
                        anchors.fill: parent
                        enabled: !EditMode.desktopDragAllowed && !chrome.selected
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: {
                            faceItem.poke()
                            faceItem.pressed = true
                        }
                        onCanceled: faceItem.pressed = false
                        onReleased: faceItem.pressed = false
                        onDoubleClicked: AiService.open()
                    }

                    EditChrome {
                        id: chrome
                        widgetId: "aiwidget"
                        target: card
                        roomW: win.roomW
                        roomH: win.roomH
                        screenName: win.screen ? win.screen.name : ""
                        onMoved: win.saveSpot(card.x, card.y)
                        onRemoveRequested: EditMode.removeFrom("aiwidget", win.screen ? win.screen.name : "")
                    }

                    AiFace {
                        id: faceItem
                        anchors.fill: parent
                        mt: win.mt
                        // A hidden kitten costs nothing: Focus Mode suspended,
                        // or the card swallowed, stops every timer inside.
                        active: (win.live || EditMode.active) && !gate.suspended
                        hasPointer: petArea.enabled && petArea.containsMouse && !dragArea.drag.active
                        pointerX: petArea.mouseX
                        pointerY: petArea.mouseY
                        dragging: dragArea.drag.active
                    }
                }
            }
        }
    }
}
