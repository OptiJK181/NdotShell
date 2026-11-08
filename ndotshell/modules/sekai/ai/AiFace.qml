import QtQuick
import qs.services
import qs.modules.common

// AiFace — the desktop pet: a Nothing slab wearing two dot-matrix eyes and a
// speech bubble set in Ndot 55, Nothing's own font. Its mood is AiService's
// business (faceMood): while the model thinks the pupils orbit, while it
// writes they bounce, and its words decide the face afterwards — happy with
// exclamations or good news, sad when it could not help, curious when it asks
// back, X-eyed on an error.
//
// It is also a pet: hover it and the eyes follow the pointer while the bubble
// repeats what it said; press it and it startles; drag it and it rides happy;
// leave it alone long enough and it dozes off, blinking in its sleep.
// `qs -c ndotshell ipc call ai face happy` pins a mood for 8 s.
//
// Pure visuals: the orb (AiOrb.qml) owns the window, the drag and the chat.
Item {
    id: face

    property var mt
    property real uiScale: 1
    // Fed by the orb's mouse area and drag handler.
    property bool hasPointer: false
    property real pointerX: 0
    property real pointerY: 0
    property bool dragging: false
    property bool pressed: false

    // ===== sizes (the window is this big when collapsed) =====
    readonly property real faceW: 118 * uiScale
    readonly property real faceH: 86 * uiScale
    readonly property real gap: 10 * uiScale
    readonly property real bubbleMaxW: 268 * uiScale
    readonly property real bubbleMaxH: 88 * uiScale
    readonly property real bubbleZone: bubbleMaxH + gap
    // The bubble is visual only: the input mask (see AiOrb) covers the slab,
    // so clicks over the bubble fall through to the wallpaper.
    readonly property real contentW: Math.max(faceW, bubbleMaxW)
    readonly property real contentH: faceH + bubbleZone

    implicitWidth: contentW
    implicitHeight: contentH

    // ===== mood engine =====
    readonly property string mood: AiService.faceMood
    readonly property bool streaming: AiService.streamingText !== ""
    property bool drowsy: false
    property bool blinking: false
    property int lookX: 0
    property int lookY: 0
    property var seq: []
    property var staticFrame: null
    property int seqIndex: 0

    readonly property string shownMood: dragging ? "happy"
        : (pressed ? "startle"
        : (drowsy && mood === "neutral" && !hasPointer ? "sleepy" : mood))
    onShownMoodChanged: applyMood()
    Component.onCompleted: applyMood()

    // Dot frames: 5 rows of 5, '#' a lit dot, 'o' the pupil, '.' dark.
    readonly property var frames: ({
        blink: [".....", ".....", "#####", ".....", "....."],
        sleep: [".....", ".....", ".###.", ".....", "....."],
        happy: ["#...#", "#...#", ".#.#.", "..#..", "....."],
        ouch:  ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
        wide:  [".###.", "#####", "#####", "#####", ".###."]
    })

    // The ring eye with its pupil planted at (dx, dy), each -1..1.
    function look(dx, dy) {
        const rows = [".###.", "#...#", "#...#", "#...#", ".###."]
        const r = 2 + dy
        const c = 2 + dx
        rows[r] = rows[r].substring(0, c) + "o" + rows[r].substring(c + 1)
        return rows
    }

    function frameFor(i) {
        if (blinking) return frames.blink
        if (seq.length > 0) return seq[((i % seq.length) + seq.length) % seq.length]
        if (staticFrame) return staticFrame
        return look(lookX, lookY)
    }

    function applyMood() {
        seqIndex = 0
        blinking = false
        switch (shownMood) {
        case "thinking":
            // the pupils circle, like thoughts going round
            seq = [look(-1, -1), look(0, -1), look(1, -1), look(1, 0),
                   look(1, 1), look(0, 1), look(-1, 1), look(-1, 0)]
            seqTimer.interval = 220
            staticFrame = null
            break
        case "talking":
            // quick pupils, the words are coming out
            seq = [look(0, 0), look(0, -1), look(0, 1), look(0, -1)]
            seqTimer.interval = 180
            staticFrame = null
            break
        case "happy":
            seq = []
            staticFrame = frames.happy
            bounce.restart()
            break
        case "sad":
            seq = []
            staticFrame = look(0, 1)   // eyes down
            break
        case "curious":
            seq = []
            staticFrame = look(1, -1)  // leaning in, looking up
            break
        case "ouch":
            seq = []
            staticFrame = frames.ouch
            break
        case "sleepy":
            seq = [frames.blink, frames.sleep]
            seqTimer.interval = 1100
            staticFrame = null
            break
        case "startle":
            seq = []
            staticFrame = frames.wide
            pop.restart()
            break
        default:
            seq = []
            staticFrame = null
            lookX = 0
            lookY = 0
        }
    }

    function poke() {
        drowsy = false
    }

    function doBlink() {
        blinking = true
        blinkOffTimer.restart()
    }

    // ===== eyes follow the pointer while it is over the pet =====
    readonly property bool following: hasPointer && !dragging && !pressed
    onFollowingChanged: {
        if (!following) {
            lookX = 0
            lookY = 0
        }
    }
    onPointerXChanged: followPointer()
    onPointerYChanged: followPointer()
    function followPointer() {
        if (!following) return
        const cx = width / 2
        const cy = contentH - faceH / 2
        lookX = Math.max(-1, Math.min(1, Math.round((pointerX - cx) / (faceW / 2))))
        lookY = Math.max(-1, Math.min(1, Math.round((pointerY - cy) / (faceH / 2))))
    }

    // ===== speech =====
    readonly property string rawSpeech: streaming
        ? AiService.streamingText
        : (AiService.lastAssistant ? AiService.lastAssistant.content : "")
    readonly property string speech: {
        const t = rawSpeech.trim()
        if (t === "") return ""
        return t.length > 180 ? t.slice(0, 179) + "…" : t
    }
    property bool bubbleFresh: false
    readonly property bool bubbleShown: !dragging && speech !== ""
        && (streaming || bubbleFresh || hasPointer)

    // ===== timers =====
    Timer {
        id: seqTimer
        repeat: true
        running: face.seq.length > 1
        onTriggered: face.seqIndex++
    }
    Timer {
        id: wanderTimer
        repeat: true
        running: face.shownMood === "neutral" && !face.following
        interval: 2400
        onTriggered: {
            if (Math.random() < 0.3) {
                face.doBlink()
                return
            }
            const dirs = [-1, 0, 1]
            face.lookX = dirs[Math.floor(Math.random() * 3)]
            face.lookY = dirs[Math.floor(Math.random() * 3)]
        }
    }
    Timer {
        id: blinkTimer
        repeat: true
        running: face.shownMood === "neutral" || face.shownMood === "curious"
        interval: 3600
        onTriggered: face.doBlink()
    }
    Timer {
        id: blinkOffTimer
        interval: 130
        onTriggered: face.blinking = false
    }
    Timer {
        id: drowsyTimer
        interval: 45000
        running: face.shownMood === "neutral" && !face.following && !face.pressed
        onTriggered: face.drowsy = true
    }
    Timer {
        id: freshTimer
        repeat: true
        running: face.visible
        interval: 400
        onTriggered: face.bubbleFresh = !AiService.busy && AiService.lastReplyAt > 0
            && (Date.now() - AiService.lastReplyAt) < 7000
    }

    // ===== one eye: a 5x5 dot matrix =====
    component Eye: Item {
        id: eye
        property var frame: [".....", ".....", ".....", ".....", "....."]
        property color litColor
        property color pupilColor
        readonly property real cell: 8 * face.uiScale
        readonly property real dotR: 2.6 * face.uiScale
        readonly property real pupilR: 3.4 * face.uiScale
        width: cell * 5
        height: cell * 5

        Repeater {
            model: 25

            delegate: Rectangle {
                required property int index
                readonly property string ch: (eye.frame[Math.floor(index / 5)] || ".....").charAt(index % 5)

                x: (index % 5) * eye.cell + (eye.cell - width) / 2
                y: Math.floor(index / 5) * eye.cell + (eye.cell - height) / 2
                width: ch === "o" ? eye.pupilR * 2 : eye.dotR * 2
                height: width
                radius: width / 2
                visible: ch !== "."
                color: ch === "o" ? eye.pupilColor : eye.litColor
                antialiasing: true
            }
        }
    }

    // ===== the slab =====
    Rectangle {
        id: slab
        x: (face.width - face.faceW) / 2
        y: face.height - face.faceH
        width: face.faceW
        height: face.faceH
        radius: 26 * face.uiScale
        color: face.mt.nbSurface
        border.width: 1
        border.color: face.hasPointer || face.pressed ? face.mt.nbAccent : face.mt.nbBorder
        Behavior on border.color { ColorAnimation { duration: 140 } }
        transformOrigin: Item.Center

        // leans towards the pointer, squashes under a press
        rotation: face.following
            ? Math.max(-6, Math.min(6, (face.pointerX - face.width / 2) / face.width * 10)) : 0
        Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
        scale: face.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        Eye {
            x: 11 * face.uiScale
            y: (slab.height - height) / 2
            litColor: face.mt.nbInk
            pupilColor: face.streaming ? face.mt.nbAccent : face.mt.nbInk
            frame: face.frameFor(face.seqIndex)
        }
        Eye {
            x: slab.width - width - 11 * face.uiScale
            y: (slab.height - height) / 2
            litColor: face.mt.nbInk
            pupilColor: face.streaming ? face.mt.nbAccent : face.mt.nbInk
            frame: face.frameFor(face.seqIndex + (face.shownMood === "talking" ? 2 : 0))
        }

        // The Nothing red dot: the model is writing.
        Rectangle {
            visible: face.streaming
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8 * face.uiScale
            anchors.rightMargin: 8 * face.uiScale
            width: 7 * face.uiScale
            height: width
            radius: width / 2
            color: face.mt.nbAccent
        }

        // A gentle idle bob when there is nothing to say.
        SequentialAnimation on y {
            running: face.visible && !face.hasPointer && !face.dragging
                && (face.shownMood === "neutral" || face.shownMood === "sleepy")
            loops: Animation.Infinite
            NumberAnimation { from: face.height - face.faceH; to: face.height - face.faceH - 2 * face.uiScale; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { from: face.height - face.faceH - 2 * face.uiScale; to: face.height - face.faceH; duration: 1600; easing.type: Easing.InOutSine }
        }

        // the happy bounce, and the startle pop
        SequentialAnimation {
            id: bounce
            NumberAnimation { target: slab; property: "scale"; to: 1.07; duration: 130; easing.type: Easing.OutQuad }
            NumberAnimation { target: slab; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
        }
        SequentialAnimation {
            id: pop
            NumberAnimation { target: slab; property: "scale"; to: 1.12; duration: 90; easing.type: Easing.OutQuad }
            NumberAnimation { target: slab; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
        }
    }

    // ===== the speech bubble, in Nothing's dot font =====
    Rectangle {
        id: bubble
        property bool shown: face.bubbleShown

        x: (face.width - width) / 2
        y: 0
        width: face.bubbleMaxW
        height: shown ? Math.min(bubbleText.implicitHeight + 18 * face.uiScale, face.bubbleMaxH) : 0
        opacity: shown ? 1 : 0
        visible: opacity > 0.01
        radius: 14 * face.uiScale
        color: face.mt.nbSurface
        border.width: 1
        border.color: face.mt.nbBorder
        clip: true

        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            id: bubbleText
            x: 10 * face.uiScale
            y: 8 * face.uiScale
            width: bubble.width - 20 * face.uiScale
            text: face.speech
            font.family: "Ndot 55"
            font.pixelSize: 13 * face.uiScale
            color: face.mt.nbInk
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }
    }
}
