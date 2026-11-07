import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.editMode

// The desktop Now Playing widget: the track that is playing, as a card that
// sits on the desktop, under your windows and over the wallpaper, with the
// same drag, lock, scale, monitors, Edit Desktop and Focus Mode as the clock,
// the weather card and the To-Do.
//
//   The cover      the player's art, rounded, with a thin Nothing ring. When
//                 there is no art (a browser tab, a player without a cover)
//                 a dot field and the media glyph stand in.
//   The text       the track title in the display face (Ndot 55 on the Nothing
//                 theme), the artist, the album, and the player's own name.
//   NOW PLAYING    a red dot that breathes while the song plays, the state
//                 (NOW PLAYING / PAUSED / IDLE) and four little bars dancing
//                 beside it.
//   The lane       click or drag to seek, wheel for five seconds a notch. The
//                 playhead is the red dot; the times read in the display face.
//   The keys       previous, play / pause, next. They dim when the player can't
//                 do them (a radio stream has no next).
//
// The track is live: it comes from MediaSource.qml (MPRIS), the same source
// the bar's pill, the dock and the lock screen use, so clicking here, pressing
// a media key, or pausing in Spotify all stay in step. The widget's own state
// (spot, size, on / off) lives in services/NowPlayingService.qml and is
// remembered across restarts.
//
// Off until you add it (Edit Desktop's shelf, Settings -> Desktop, or the ipc).
// In Edit Desktop, with nothing playing, it still shows so you can place it.
//
// How the moving works: exactly like TodoWidget.qml. ONE transparent window
// with the card as an Item inside it. Dragging just moves that Item, so it
// stays smooth, and the window's input `mask` is only the card, so every click
// anywhere else passes straight through.
//
// Bind a key / call it from a script:
//   qs -c ndotshell ipc call nowplaying toggle        (show / hide)
//   qs -c ndotshell ipc call nowplaying size 2x2      (or: full)
//   qs -c ndotshell ipc call nowplaying toggleSize
//   qs -c ndotshell ipc call nowplaying resetPosition (if it ever ends up off-screen)
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
    // NowPlayingService), or the first screen if it has never been moved.
    property string monitor: ""

    // A copy on another monitor (WidgetClones.qml): the same widget, with a spot
    // of its own. The main copy keeps its spot in the service as before.
    property bool clone: false

    readonly property var cloneSpot: win.clone ? WidgetClones.spot("nowplaying", win.wantedScreen) : null
    readonly property bool spotReady: win.clone ? (WidgetClones.loaded && win.cloneSpot !== null) : NowPlayingService.loaded
    readonly property real spotX: win.clone ? (win.cloneSpot ? win.cloneSpot.x : -1) : NowPlayingService.posX
    readonly property real spotY: win.clone ? (win.cloneSpot ? win.cloneSpot.y : -1) : NowPlayingService.posY
    readonly property real spotScale: win.clone ? (win.cloneSpot ? win.cloneSpot.scale : 0) : NowPlayingService.posScale

    function saveSpot(x, y): void {
        if (win.clone)
            WidgetClones.setSpot("nowplaying", win.wantedScreen, x, y, win.uiScale)
        else
            NowPlayingService.setPosition(x, y, win.uiScale)
    }

    function clearSpot(): void {
        if (win.clone) {
            WidgetClones.clearSpot("nowplaying", win.wantedScreen)
        } else {
            NowPlayingService.posX = -1
            NowPlayingService.posY = -1
        }
    }

    function fixSpotScale(): void {
        if (win.clone) {
            WidgetClones.setSpot("nowplaying", win.wantedScreen, win.spotX, win.spotY, win.uiScale)
        } else {
            NowPlayingService.posScale = win.uiScale
            NowPlayingService.persist()
        }
    }

    readonly property string wantedScreen: win.monitor !== "" ? win.monitor : NowPlayingService.screenName
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
    // See TodoWidget.qml: at rest the window is just the card plus some room
    // around it, and only Edit Desktop (and dragging on an unlocked desktop)
    // gets the full screen back. Everything inside still lives in screen
    // coordinates: `shifter` slides the whole stage by the window's own position.
    readonly property bool compact: !EditMode.active && !win.gliding && EditMode.screenName === ""
        && EditMode.compactWindows && !EditMode.desktopDragAllowed && win.fullW > 0 && win.placed
    readonly property real boxPad: Math.ceil((0.16 * Math.max(card.width, card.height) + 24) * win.uiScale)
    readonly property real boxX: win.compact ? Math.max(0, Math.floor(card.x * win.uiScale - win.boxPad)) : 0
    readonly property real boxY: win.compact ? Math.max(0, Math.floor(card.y * win.uiScale - win.boxPad)) : 0
    readonly property real boxW: Math.max(1, Math.min(win.fullW,
        Math.ceil((card.x + card.width) * win.uiScale + win.boxPad)) - win.boxX)
    readonly property real boxH: Math.max(1, Math.min(win.fullH,
        Math.ceil((card.y + card.height) * win.uiScale + win.boxPad)) - win.boxY)

    // ===== the card's own size =====
    // "2x2" is the tall, centred card; "full" the wide one with the cover beside
    // the words. The service remembers which one you chose.
    readonly property bool small: NowPlayingService.small
    readonly property int cardWidth: win.small ? 320 : 384
    readonly property int cardHeight: win.small ? 300 : 266
    readonly property int pad: 18

    // ===== the track =====
    // The bar, the dock and the lock screen each have their own MediaSource too.
    // This one is only built while the window is (which is only while the widget
    // is on, or while Edit Desktop is open).
    MediaSource { id: media }

    readonly property var player: media.player
    readonly property bool present: media.present
    readonly property bool playing: media.playing

    // In Edit Desktop an idle card still shows some words, so it can be placed.
    readonly property bool demo: !media.present && (EditMode.active || EditMode.screenName !== "")
    readonly property string trackTitle: media.present ? media.title
        : (win.demo ? "Now Playing" : "Nothing playing")
    readonly property string trackArtist: media.present
        ? (media.artist !== "" ? media.artist : (win.player ? (win.player.identity ?? "") : ""))
        : (win.demo ? "Your music, on the desktop" : "Open your player to wake this up")
    readonly property string trackAlbum: media.present && win.player ? (win.player.trackAlbum ?? "") : ""
    readonly property string trackArt: media.present ? media.artUrl : ""
    readonly property string who: media.present && win.player && win.player.identity ? win.player.identity : ""
    readonly property string banner: media.present ? (media.playing ? "NOW PLAYING" : "PAUSED") : "IDLE"
    // In the Nothing theme accentCyan is the red (#d71921).
    readonly property color accent: win.mt.accentCyan

    // ===== position =====
    // Players announce their position unevenly, so it is read twice a second while
    // the card is on screen; the lane smooths the steps with a linear width
    // animation. A seek is followed at once (the lane writes the target itself).
    property real elapsed: 0
    property real trackLength: 0
    readonly property bool hasLength: win.player !== null && win.player.lengthSupported === true
        && win.trackLength > 0
    readonly property real frac: win.trackLength > 0
        ? Math.max(0, Math.min(1, win.elapsed / win.trackLength)) : 0
    readonly property bool seekable: win.player !== null && win.player.canSeek
        && win.player.positionSupported === true && win.hasLength
    readonly property bool canPrev: win.player !== null && win.player.canGoPrevious
    readonly property bool canNext: win.player !== null && win.player.canGoNext
    readonly property bool canToggle: win.player !== null && win.player.canTogglePlaying

    function readPosition(): void {
        const p = win.player
        if (!p) {
            win.elapsed = 0
            win.trackLength = 0
            return
        }
        win.trackLength = p.lengthSupported ? Math.max(0, Number(p.length) || 0) : 0
        if (!p.positionSupported) {
            win.elapsed = 0
            return
        }
        // Ask the player for its position, then read it. This runs while the card
        // is on screen whether it is playing or paused, so a seek made anywhere
        // else (playerctl, the dock, the bar) shows up here too.
        p.positionChanged()
        win.elapsed = Math.max(0, Number(p.position) || 0)
    }

    function seekTo(fraction): void {
        if (!win.seekable)
            return
        const f = Math.max(0, Math.min(1, Number(fraction) || 0))
        const target = f * win.trackLength
        win.player.positionChanged()
        win.player.position = target
        win.elapsed = target
    }

    function seekBy(seconds): void {
        if (!win.seekable)
            return
        win.player.positionChanged()
        win.seekTo((Number(win.player.position) + Number(seconds || 0)) / win.trackLength)
    }

    function togglePlay(): void {
        if (win.canToggle)
            win.player.togglePlaying()
    }

    function nextTrack(): void {
        if (win.canNext)
            win.player.next()
    }

    function prevTrack(): void {
        if (win.canPrev)
            win.player.previous()
    }

    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: win.visible && win.present
        onTriggered: win.readPosition()
    }

    Connections {
        target: media
        ignoreUnknownSignals: true
        function onTitleChanged() { win.readPosition() }
        function onPresentChanged() { win.readPosition() }
    }

    // ===== on / off =====
    FocusGate {
        id: gate
        widgetId: "nowplaying"
        screenName: win.screen ? win.screen.name : ""
    }

    readonly property bool switchedOn: NowPlayingService.loaded && NowPlayingService.shown
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
        running: NowPlayingService.loaded
        onTriggered: win.armed = true
    }

    property bool placed: false

    // `live`: the card is on, or still being swallowed.
    readonly property bool live: win.want || win.reveal > 0.001

    // Not mapped while the widget is off: a full-screen transparent layer that is
    // only sitting there still costs the compositor a blend on every frame.
    visible: NowPlayingService.loaded && (win.live || EditMode.active)

    // Always BELOW the dock: the widgets rest on Background (mapped after the
    // wallpaper, so over it) and the dock is on Bottom or Top, so the dock is never
    // behind a widget. Up a layer while this widget is edited or moved
    // (EditChrome.raised), so the one edited last is in front of the other widgets.
    WlrLayershell.layer: (chrome.raised || WallpaperService.restacking) ? WlrLayer.Bottom : WlrLayer.Background
    WlrLayershell.namespace: "ndotshell-nowplaying"
    // Nothing here needs to type: the shelf keeps the keyboard while editing.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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
            // A new card rests in the upper middle of the desktop, clear of the
            // clock (left), the calendar (right) and the dock (bottom). The cover
            // is the part the eye looks for, so the card keeps clear of the very
            // top and bottom.
            x = Math.round((win.roomW - card.width) / 2)
            y = Math.max(96, Math.round(win.roomH * 0.16))
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
        target: NowPlayingService
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
        function onSizeChanged() { Qt.callLater(win.place); settle.restart() }
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
        widgetId: "nowplaying"
        target: card
        pixelRatio: win.uiScale
    }

    // ===== small building blocks =====
    // A red state dot: breathes while the song plays, still when it is paused.
    component DotMark: Rectangle {
        id: dot
        property bool live: false
        property color accent: "#d71921"
        readonly property var mt: Theme.of(QsWindow.window)

        width: 8
        height: 8
        radius: 4
        color: dot.live ? dot.accent : dot.mt.inkSub
        opacity: dot.live ? 1 : 0.55

        SequentialAnimation on opacity {
            running: dot.live
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 720; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 720; easing.type: Easing.InOutQuad }
        }
    }

    // Four little bars that dance while the song plays.
    component Equalizer: Row {
        id: eq
        property bool live: false
        property color accent: "#d71921"
        property real phase: 0

        spacing: 2
        height: 14

        FrameAnimation {
            running: eq.live
            onTriggered: eq.phase += frameTime
        }

        Repeater {
            model: 4

            Rectangle {
                required property int index
                readonly property real wave: Math.abs(Math.sin(eq.phase * (2.4 + index * 0.45) + index * 1.3))
                width: 3
                height: eq.live ? 3 + 10 * wave : 3
                radius: 1.5
                color: eq.accent
                opacity: eq.live ? 1 : 0.5
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // The cover: clipped to a rounded square, with a thin ring on top.
    component Cover: Item {
        id: cov
        property string source: ""
        property real side: 104
        readonly property var mt: Theme.of(QsWindow.window)

        width: cov.side
        height: cov.side

        RoundClip {
            anchors.fill: parent
            radii: [13, 13, 13, 13]
            color: cov.mt.surfaceDivider

            Image {
                id: coverImage
                anchors.fill: parent
                source: cov.source
                visible: status === Image.Ready
                asynchronous: true
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(Math.max(1, cov.side) * 2, Math.max(1, cov.side) * 2)
                opacity: win.playing || !win.present ? 1 : 0.6

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            DotField {
                anchors.fill: parent
                visible: coverImage.status !== Image.Ready
                corner: "br"
                spacing: 9
                maxRadius: 1.5
                dotColor: Qt.rgba(1, 1, 1, 0.16)
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: coverImage.status !== Image.Ready
                name: "graphic_eq"
                size: Math.round(cov.side * 0.3)
                weight: 500
                color: cov.mt.inkSub
                opacity: 0.8
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 13
            color: "transparent"
            border.width: 1.5
            border.color: cov.mt.line
            antialiasing: true
        }
    }

    // The seek lane: a thin bar, a red playhead dot, the two times.
    component Lane: Item {
        id: lane
        property var player: null
        property real elapsed: 0
        property real length: 0
        property bool live: false
        property color accent: "#d71921"
        readonly property var mt: Theme.of(QsWindow.window)

        signal seekRequested(real fraction)
        signal seekByRequested(real seconds)

        readonly property bool hasLength: lane.length > 0
        readonly property bool seekable: lane.player !== null && lane.player.canSeek
            && lane.player.positionSupported === true && lane.hasLength
        readonly property real shownFrac: lane.hasLength
            ? Math.max(0, Math.min(1, lane.elapsed / lane.length)) : 0
        property real hoverFrac: 0
        property bool dragging: false
        property real dragFrac: 0
        readonly property real frac: lane.dragging ? lane.dragFrac : lane.shownFrac

        height: 26

        function fmt(sec) {
            sec = Math.max(0, Math.floor(Number(sec) || 0))
            const h = Math.floor(sec / 3600)
            const m = Math.floor((sec % 3600) / 60)
            const s = sec % 60
            return h > 0 ? (h + ":" + ("0" + m).slice(-2) + ":" + ("0" + s).slice(-2))
                         : (m + ":" + ("0" + s).slice(-2))
        }

        Item {
            id: track
            x: 0
            y: 2
            width: parent.width
            height: 4

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: lane.mt.surfaceDivider
            }

            Rectangle {
                x: 0
                y: 0
                height: 4
                radius: 2
                width: Math.max(0, track.width * lane.frac)
                color: lane.accent

                Behavior on width {
                    enabled: !lane.dragging
                    NumberAnimation { duration: 460; easing.type: Easing.Linear }
                }
            }

            Repeater {
                model: 3

                Rectangle {
                    required property int index
                    x: track.width * (index + 1) / 4 - 1
                    y: -1
                    width: 2
                    height: 6
                    radius: 1
                    color: lane.mt.line
                    opacity: 0.5
                }
            }

            // The playhead: a small round dot, Nothing's own punctuation.
            Rectangle {
                visible: lane.seekable
                width: 8
                height: 8
                radius: 4
                y: -2
                color: lane.accent
                x: Math.max(0, Math.min(track.width - width, track.width * lane.frac - width / 2))

                Behavior on x {
                    enabled: !lane.dragging
                    NumberAnimation { duration: 460; easing.type: Easing.Linear }
                }
            }
        }

        Text {
            y: 9
            text: lane.fmt(lane.frac * lane.length)
            color: lane.mt.inkSub
            font.family: lane.mt.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
        }

        Text {
            y: 9
            anchors.right: parent.right
            text: lane.fmt(lane.length)
            color: lane.mt.inkSub
            font.family: lane.mt.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
        }

        MouseArea {
            id: laneArea
            anchors.fill: parent
            anchors.topMargin: -4
            enabled: lane.seekable
            hoverEnabled: true
            cursorShape: lane.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
            preventStealing: true

            function fracAt(mx) {
                return Math.max(0, Math.min(1, mx / Math.max(1, track.width)))
            }

            onPressed: mouse => {
                lane.dragFrac = fracAt(mouse.x)
                lane.dragging = true
            }

            onPositionChanged: mouse => {
                lane.hoverFrac = fracAt(mouse.x)
                if (lane.dragging)
                    lane.dragFrac = lane.hoverFrac
            }

            onReleased: mouse => {
                if (!lane.dragging)
                    return
                lane.dragging = false
                lane.seekRequested(lane.dragFrac)
            }

            onCanceled: lane.dragging = false

            onWheel: wheel => lane.seekByRequested(wheel.angleDelta.y > 0 ? 5 : -5)
        }
    }

    // One round key: previous / play / next.
    component MediaKey: Item {
        id: key
        property string icon: ""
        property bool big: false
        property bool usable: true
        property color accent: "#d71921"
        readonly property var mt: Theme.of(QsWindow.window)

        signal activated()

        width: key.big ? 46 : 36
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: key.big
                ? (key.usable ? (keyArea.containsMouse ? Qt.lighter(key.accent, 1.2) : key.accent) : key.mt.surfaceDivider)
                : (keyArea.containsMouse && key.usable ? key.mt.surfaceHover : "transparent")
            border.width: key.big ? 0 : (keyArea.containsMouse && key.usable ? 1.5 : 0)
            border.color: key.mt.line

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: key.icon
                size: key.big ? 26 : 20
                weight: 600
                color: key.big ? "#ffffff"
                    : (keyArea.containsMouse && key.usable ? key.accent : key.mt.ink)
                opacity: key.usable ? 1 : 0.35
            }
        }

        MouseArea {
            id: keyArea
            anchors.fill: parent
            enabled: key.usable
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: key.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: key.activated()
        }
    }

    component Controls: Row {
        id: ctl
        property bool live: false
        property bool canPrev: false
        property bool canNext: false
        property bool canToggle: false
        property color accent: "#d71921"

        signal prevRequested()
        signal toggleRequested()
        signal nextRequested()

        spacing: 16
        height: 46

        MediaKey {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_previous"
            usable: ctl.canPrev
            accent: ctl.accent
            onActivated: ctl.prevRequested()
        }

        MediaKey {
            anchors.verticalCenter: parent.verticalCenter
            icon: ctl.live ? "pause" : "play_arrow"
            big: true
            usable: ctl.canToggle
            accent: ctl.accent
            onActivated: ctl.toggleRequested()
        }

        MediaKey {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_next"
            usable: ctl.canNext
            accent: ctl.accent
            onActivated: ctl.nextRequested()
        }
    }

    // The header: the state dot, NOW PLAYING / PAUSED / IDLE, the dancing bars,
    // and the player's own name on the right.
    component Header: Item {
        id: head
        property string label: ""
        property bool live: false
        property string who: ""
        property color accent: "#d71921"
        readonly property var mt: Theme.of(QsWindow.window)

        height: 16

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            DotMark {
                anchors.verticalCenter: parent.verticalCenter
                live: head.live
                accent: head.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: head.label
                color: head.mt.inkSub
                font.family: head.mt.fontDisplay
                font.pixelSize: 11
                font.weight: Font.ExtraBold
                font.letterSpacing: 2.5
            }

            Equalizer {
                anchors.verticalCenter: parent.verticalCenter
                live: head.live
                accent: head.accent
            }
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, head.width * 0.42)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: head.who
            color: head.mt.inkSub
            opacity: 0.75
            font.family: head.mt.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
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

                    onWidthChanged: {
                        if (!chrome.dragging && !dragArea.drag.active)
                            win.place()
                    }

                    onHeightChanged: {
                        if (!chrome.dragging && !dragArea.drag.active) {
                            win.place()
                            settle.restart()
                        }
                    }

                    // The housing: the same outline / pale ring / fill / hard shadow
                    // as the other desktop cards (Pill.qml). On the Nothing theme the
                    // palette turns it into black glass with grey rings.
                    Pill {
                        anchors.fill: parent
                        cornerRadius: 16
                        ringWidth: win.mt.borderWidth + win.mt.outerRingWidth
                        ringColorTop: win.mt.surfaceRing
                        ringColorBottom: ringColorTop
                        fillColor: win.mt.surface
                    }

                    // Edit Desktop: outline, corner diamonds, a tag and a drag shield.
                    EditChrome {
                        id: chrome
                        widgetId: "nowplaying"
                        target: card
                        roomW: win.roomW
                        roomH: win.roomH
                        screenName: win.screen ? win.screen.name : ""
                        onMoved: win.saveSpot(card.x, card.y)
                        onRemoveRequested: EditMode.removeFrom("nowplaying", win.screen ? win.screen.name : "")
                    }

                    // Left button: drag the card on the normal desktop, unless Lock all
                    // is on. Sits under the content, so the keys and the lane win their
                    // own clicks and everything else is "grab here".
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

                    // Edit Desktop: flip between the wide card and the square one.
                    SizeKey {
                        shown: chrome.selected
                        small: NowPlayingService.small
                        onToggled: NowPlayingService.toggleSize()
                    }

                    // ===== FULL: cover beside the words =====
                    Column {
                        id: fullCol
                        visible: !win.small
                        x: win.pad
                        y: 16
                        width: card.width - win.pad * 2
                        spacing: 12

                        Header {
                            width: parent.width
                            label: win.banner
                            live: win.playing
                            who: win.who
                            accent: win.accent
                        }

                        Item {
                            width: parent.width
                            height: 104

                            Cover {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                side: 104
                                source: win.trackArt
                            }

                            Column {
                                x: 118
                                width: parent.width - 118
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: win.trackTitle
                                    color: win.mt.ink
                                    font.family: win.mt.fontDisplay
                                    font.pixelSize: 22
                                    font.weight: Font.ExtraBold
                                    font.styleName: win.mt.fontStyleBold
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: win.trackArtist
                                    color: win.mt.inkSub
                                    font.family: win.mt.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: win.trackAlbum
                                    visible: text !== ""
                                    color: win.mt.inkSub
                                    opacity: 0.65
                                    font.family: win.mt.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Lane {
                            width: parent.width
                            visible: win.present && win.hasLength
                            player: win.player
                            elapsed: win.elapsed
                            length: win.trackLength
                            live: win.playing
                            accent: win.accent
                            onSeekRequested: fraction => win.seekTo(fraction)
                            onSeekByRequested: seconds => win.seekBy(seconds)
                        }

                        Controls {
                            x: (parent.width - width) / 2
                            live: win.playing
                            canPrev: win.canPrev
                            canNext: win.canNext
                            canToggle: win.canToggle
                            accent: win.accent
                            onPrevRequested: win.prevTrack()
                            onToggleRequested: win.togglePlay()
                            onNextRequested: win.nextTrack()
                        }
                    }

                    // ===== 2x2: centred, tall =====
                    Column {
                        id: smallCol
                        visible: win.small
                        x: win.pad
                        y: 16
                        width: card.width - win.pad * 2
                        spacing: 8

                        Header {
                            width: parent.width
                            label: win.banner
                            live: win.playing
                            who: win.who
                            accent: win.accent
                        }

                        Item {
                            width: parent.width
                            height: 100

                            Cover {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                side: 100
                                source: win.trackArt
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: win.trackTitle
                            color: win.mt.ink
                            font.family: win.mt.fontDisplay
                            font.pixelSize: 20
                            font.weight: Font.ExtraBold
                            font.styleName: win.mt.fontStyleBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: win.trackArtist
                            color: win.mt.inkSub
                            font.family: win.mt.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Lane {
                            width: parent.width
                            visible: win.present && win.hasLength
                            player: win.player
                            elapsed: win.elapsed
                            length: win.trackLength
                            live: win.playing
                            accent: win.accent
                            onSeekRequested: fraction => win.seekTo(fraction)
                            onSeekByRequested: seconds => win.seekBy(seconds)
                        }

                        Controls {
                            x: (parent.width - width) / 2
                            live: win.playing
                            canPrev: win.canPrev
                            canNext: win.canNext
                            canToggle: win.canToggle
                            accent: win.accent
                            onPrevRequested: win.prevTrack()
                            onToggleRequested: win.togglePlay()
                            onNextRequested: win.nextTrack()
                        }
                    }
                }
            }
        }
    }
}
