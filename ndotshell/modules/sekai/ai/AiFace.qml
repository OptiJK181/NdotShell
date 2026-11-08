import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// AiFace — the AI pet's card content, wearing the Now Playing widget's own
// clothes: the Pill housing, a header with a breathing red dot, a banner that
// reads THINKING / TYPING / ERROR / IDLE, and four little bars dancing while
// the model works. The eyes are this card's cover: two 5×5 dot matrices that
// blink, wander, follow the pointer, and wear the mood the reply leaves
// behind (happy `^^`, sad eyes down, error `x x`). The words arrive where the
// track title would sit, set in fontDisplay — Ndot 55 on the Nothing theme —
// live, word by word, while the model writes. Under them, the ask row: type
// and Enter (or the red key) sends the question from the card itself; while
// the pet is talking the key stays grey and your text is kept.
//
// Everything here is design pixels: the widget (AiWidget.qml) hosts this
// inside a ScaleHost, and owns the window, the drag and the chat drawer.
// The mood is AiService's business (faceMood). `ipc call ai face happy`
// pins one; `ipc call ai ask "…"` sends from anywhere.
Item {
    id: face

    property var mt
    // Fed by the widget's mouse areas and drag handler.
    property bool hasPointer: false
    property real pointerX: 0
    property real pointerY: 0
    property bool dragging: false
    property bool pressed: false

    // ===== the card's size, in design pixels =====
    readonly property int cardW: 320
    readonly property int cardH: 198
    readonly property int pad: 18
    readonly property color accent: mt.accentCyan // the Nothing red on the dot theme

    implicitWidth: cardW
    implicitHeight: cardH

    // ===== mood engine =====
    readonly property string mood: AiService.faceMood
    readonly property bool streaming: AiService.streamingText !== ""
    readonly property bool busy: AiService.busy
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

    // The banner, Now Playing style: what the model is up to right now.
    readonly property string banner: busy
        ? (streaming ? "TYPING" : "THINKING")
        : (AiService.error !== "" ? "ERROR" : "IDLE")

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

    // ===== eyes follow the pointer while it is over the card =====
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
        const cx = cardW / 2
        const cy = cardH * 0.42
        lookX = Math.max(-1, Math.min(1, Math.round((pointerX - cx) / (cardW / 2))))
        lookY = Math.max(-1, Math.min(1, Math.round((pointerY - cy) / (cardH / 2))))
    }

    // ===== the words, where the track title sits =====
    readonly property string rawSpeech: streaming
        ? AiService.streamingText
        : (AiService.lastAssistant ? AiService.lastAssistant.content : "")
    readonly property string speech: {
        const t = rawSpeech.trim()
        if (t === "") return ""
        return t.length > 140 ? t.slice(0, 139) + "…" : t
    }
    readonly property string headline: speech !== "" ? speech : "Pregúntame lo que sea"

    // ===== the ask row =====
    function sendQuestion() {
        const t = askInput.text.trim()
        if (t === "") return
        if (face.busy) return   // the pet is talking: keep your text
        AiService.send(t)
        askInput.text = ""
    }

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

    // ===== one eye: a 5×5 dot matrix =====
    component Eye: Item {
        id: eye
        property var frame: [".....", ".....", ".....", ".....", "....."]
        property color litColor
        property color pupilColor
        readonly property real cell: 8
        readonly property real dotR: 2.6
        readonly property real pupilR: 3.4
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

    // ===== the card =====
    Item {
        id: card
        anchors.fill: parent

        transformOrigin: Item.Center
        scale: face.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        // leans towards the pointer
        rotation: face.following
            ? Math.max(-3, Math.min(3, (face.pointerX - face.cardW / 2) / face.cardW * 8)) : 0
        Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

        // The same housing as the other desktop cards: outline, pale ring,
        // fill, hard shadow. Black glass with grey rings on the Nothing theme.
        Pill {
            anchors.fill: parent
            cornerRadius: 16
            ringWidth: face.mt.borderWidth + face.mt.outerRingWidth
            ringColorTop: face.mt.surfaceRing
            ringColorBottom: ringColorTop
            fillColor: face.mt.surface
        }

        Column {
            x: face.pad
            y: 14
            width: face.cardW - face.pad * 2
            spacing: 8

            // ===== header: dot + banner + bars · provider on the right =====
            Item {
                width: parent.width
                height: 16

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // The red state dot: breathes while the model works.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: face.busy ? face.accent : face.mt.inkSub
                        opacity: face.busy ? 1 : 0.55

                        SequentialAnimation on opacity {
                            running: face.busy
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 720; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 720; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.banner
                        color: face.mt.inkSub
                        font.family: face.mt.fontDisplay
                        font.pixelSize: 11
                        font.weight: Font.ExtraBold
                        font.letterSpacing: 2.5
                    }

                    // Four little bars that dance while the model works.
                    Row {
                        id: eq
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        height: 14
                        property real phase: 0

                        FrameAnimation {
                            running: face.busy
                            onTriggered: eq.phase += frameTime
                        }

                        Repeater {
                            model: 4

                            Rectangle {
                                required property int index
                                readonly property real wave: Math.abs(Math.sin(eq.phase * (2.4 + index * 0.45) + index * 1.3))
                                width: 3
                                height: face.busy ? 3 + 10 * wave : 3
                                radius: 1.5
                                color: face.accent
                                opacity: face.busy ? 1 : 0.5
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width * 0.42)
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: AiService.providerLabel
                    color: face.mt.inkSub
                    opacity: 0.75
                    font.family: face.mt.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            // ===== the eyes, this card's cover =====
            Item {
                width: parent.width
                height: 44

                Eye {
                    x: (parent.width - width) / 2 - 9
                    y: (parent.height - height) / 2
                    litColor: face.mt.ink
                    pupilColor: face.streaming ? face.accent : face.mt.ink
                    frame: face.frameFor(face.seqIndex)
                }
                Eye {
                    x: (parent.width - width) / 2 + 9
                    y: (parent.height - height) / 2
                    litColor: face.mt.ink
                    pupilColor: face.streaming ? face.accent : face.mt.ink
                    frame: face.frameFor(face.seqIndex + (face.shownMood === "talking" ? 2 : 0))
                }
            }

            // ===== the words, in the display face =====
            Text {
                width: parent.width
                height: 32
                text: face.headline
                color: face.mt.ink
                font.family: face.mt.fontDisplay
                font.pixelSize: 15
                font.weight: Font.ExtraBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                lineHeight: 1.05
            }

            Text {
                width: parent.width
                text: face.speech !== "" ? AiService.model : "doble toque abre el chat · arrastra desde Edit Desktop"
                color: face.mt.inkSub
                opacity: 0.65
                font.family: face.mt.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            // ===== the ask row: type here, Enter or the red key sends =====
            Item {
                width: parent.width
                height: 34

                Rectangle {
                    id: field
                    width: parent.width - 42
                    height: 34
                    radius: 12
                    color: face.mt.surfaceDivider
                    border.width: 1
                    border.color: askInput.activeFocus ? face.accent : face.mt.line

                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    TextInput {
                        id: askInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        clip: true
                        selectByMouse: true
                        color: face.mt.ink
                        selectionColor: face.accent
                        selectedTextColor: face.mt.surface
                        font.family: face.mt.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        verticalAlignment: TextInput.AlignVCenter
                        onAccepted: face.sendQuestion()
                        Keys.onEscapePressed: {
                            askInput.text = ""
                            askInput.focus = false
                        }

                        Text {
                            visible: askInput.text === "" && !askInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Pregúntale algo…"
                            color: face.mt.inkSub
                            font.family: face.mt.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }
                }

                MouseArea {
                    anchors.fill: field
                    cursorShape: Qt.IBeamCursor
                    onPressed: askInput.forceActiveFocus()
                }

                // the red key: send (grey while the pet is talking or the
                // field is empty)
                Rectangle {
                    x: field.width + 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34
                    radius: 17
                    color: !face.busy && askInput.text.trim() !== "" ? face.accent : face.mt.surfaceDivider

                    Behavior on color { ColorAnimation { duration: 140 } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "send-square"
                        size: 16
                        weight: 600
                        color: !face.busy && askInput.text.trim() !== "" ? "#ffffff" : face.mt.inkSub
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: face.sendQuestion()
                    }
                }
            }
        }

        // the happy bounce, and the startle pop
        SequentialAnimation {
            id: bounce
            NumberAnimation { target: card; property: "scale"; to: 1.04; duration: 130; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
        }
        SequentialAnimation {
            id: pop
            NumberAnimation { target: card; property: "scale"; to: 1.06; duration: 90; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBack }
        }
    }
}
