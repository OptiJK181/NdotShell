import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// AiFace — two little balls with feelings. The card keeps the Now Playing
// widget's clothes (Pill housing, header with a breathing red dot,
// THINKING / TYPING / ERROR / IDLE banner, dancing bars), and the face is
// just two round eyes that follow the pointer, blink, and wear the mood the
// reply leaves behind: normal, happy (^ ^ with a bounce), angry (a lid cuts
// each ball), sad (droopy, with a falling tear), asleep (shut lines with
// drifting z's), startled (wide). The words arrive where the track title
// would sit, in fontDisplay (Ndot 55 on the Nothing theme), and under them
// the ask row: type and Enter sends the question from the card. A reply may
// carry one ```run``` block — it shows up as the red Ejecutar key; nothing
// runs until it is pressed.
//
// Everything here is design pixels: the widget (AiWidget.qml) hosts this
// inside a ScaleHost and owns the window, the drag and the chat drawer. The
// mood is AiService's business (faceMood); `ipc call ai face happy` pins one.
// When `active` is false (Focus Mode hid the card) every timer stops: a
// hidden pet costs nothing.
Item {
    id: face

    property var mt
    property bool active: true
    // Fed by the widget's mouse areas and drag handler.
    property bool hasPointer: false
    property real pointerX: 0
    property real pointerY: 0
    property bool dragging: false
    property bool pressed: false

    // ===== the card's size, in design pixels =====
    readonly property int cardW: 320
    readonly property int cardH: 204
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
    property var seq: []   // orbit / bounce points: [{x,y}, …]
    property int seqIndex: 0
    property string eyeStyle: "open" // open | happy | angry | sad | sleep | wide
    property real runFlash: 0

    Timer {
        id: runFlashTimer
        interval: 2500
        onTriggered: face.runFlash = 0
    }

    readonly property string shownMood: dragging ? "happy"
        : (pressed ? "wide"
        : (drowsy && mood === "neutral" && !hasPointer ? "sleepy" : mood))
    onShownMoodChanged: applyMood()
    Component.onCompleted: applyMood()

    // The banner, Now Playing style: what the model is up to right now.
    readonly property string banner: busy
        ? (streaming ? "TYPING" : "THINKING")
        : (AiService.error !== "" ? "ANGRY" : "IDLE")

    function applyMood() {
        seqIndex = 0
        blinking = false
        switch (shownMood) {
        case "thinking":
            // the gaze circles, like thoughts going round
            eyeStyle = "open"
            seq = [{x: -1, y: -1}, {x: 0, y: -1}, {x: 1, y: -1}, {x: 1, y: 0},
                   {x: 1, y: 1}, {x: 0, y: 1}, {x: -1, y: 1}, {x: -1, y: 0}]
            seqTimer.interval = 260
            break
        case "talking":
            // quick glances, the words are coming out
            eyeStyle = "open"
            seq = [{x: 0, y: 0}, {x: 0, y: -1}, {x: 0, y: 1}, {x: 0, y: -1}]
            seqTimer.interval = 220
            break
        case "happy":
            eyeStyle = "happy"
            lookX = 0
            lookY = 0
            bounce.restart()
            break
        case "sad":
            eyeStyle = "sad"
            lookX = 0
            lookY = 0
            break
        case "curious":
            eyeStyle = "open"
            lookX = 1
            lookY = -1
            break
        case "angry":
            eyeStyle = "angry"
            lookX = 0
            lookY = 0
            break
        case "sleepy":
            eyeStyle = "sleep"
            lookX = 0
            lookY = 0
            break
        case "startle":
            eyeStyle = "wide"
            wob = 1
            pop.restart()
            break
        default:
            eyeStyle = "open"
            lookX = 0
            lookY = 0
        }
    }

    // The look point for eye `i` (the right eye rides one step ahead while
    // talking, so the glances alternate).
    function lookOf(i) {
        if (seq.length > 0)
            return seq[((i + seqIndex) % seq.length + seq.length) % seq.length]
        return {x: lookX, y: lookY}
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
        const cy = cardH * 0.38
        lookX = Math.max(-1, Math.min(1, Math.round((pointerX - cx) / (cardW / 2))))
        lookY = Math.max(-1, Math.min(1, Math.round((pointerY - cy) / (cardH / 2))))
    }

    // ===== the words, where the track title sits =====
    readonly property string rawSpeech: streaming
        ? AiService.streamingText
        : (AiService.lastAssistant ? AiService.lastAssistant.content : "")
    readonly property string speech: {
        // a ```run``` block is not words: it renders as the Ejecutar key below
        let t = rawSpeech.replace(/```run[\s\S]*?```/g, "").trim()
        if (t === "" && rawSpeech.indexOf("```run") !== -1) t = "Te preparé un comando"
        if (t === "") return ""
        return t.length > 140 ? t.slice(0, 139) + "…" : t
    }
    readonly property string headline: speech !== "" ? speech : "¿En qué te ayudo?"
    readonly property string pendingRun: AiService.lastRunBlocks.length > 0
        ? AiService.lastRunBlocks[AiService.lastRunBlocks.length - 1] : ""

    // ===== the ask row =====
    function sendQuestion() {
        const t = askInput.text.trim()
        if (t === "") return
        if (face.busy) return   // the pet is talking: keep your text
        AiService.send(t)
        askInput.text = ""
    }

    // ===== timers (all stop when Focus Mode hides the card) =====
    Timer {
        id: seqTimer
        repeat: true
        running: face.active && face.seq.length > 1
        onTriggered: face.seqIndex++
    }
    Timer {
        id: wanderTimer
        repeat: true
        running: face.active && face.shownMood === "neutral" && !face.following
        interval: 2600
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
        running: face.active && (face.shownMood === "neutral" || face.shownMood === "curious")
        interval: 3800
        onTriggered: face.doBlink()
    }
    Timer {
        id: blinkOffTimer
        interval: 140
        onTriggered: face.blinking = false
    }
    Timer {
        id: drowsyTimer
        interval: 45000
        running: face.active && face.shownMood === "neutral" && !face.following && !face.pressed
        onTriggered: face.drowsy = true
    }

    // ===== one eye: a ball, or the shape its feeling wears =====
    component Bolita: Item {
        id: eye
        property string style: "open"
        property bool flip: false   // the right eye mirrors lids and arcs
        property int lookX: 0
        property int lookY: 0
        property color ink
        property color paper

        readonly property bool isBall: style === "open" || style === "wide" || style === "angry" || style === "sad"
        readonly property bool squint: face.blinking && (style === "open" || style === "wide")

        width: 26
        height: 26

        // the ball — a plain round bolita, the whole face's heart
        Rectangle {
            id: ball
            width: eye.style === "wide" ? 20 : 15
            height: eye.squint ? 3.5 : (eye.style === "sad" ? 12 : width)
            radius: eye.squint ? 1.75 : width / 2
            color: eye.ink
            visible: eye.isBall
            x: (parent.width - width) / 2 + eye.lookX * 3
            y: (parent.height - height) / 2 + eye.lookY * 2 + (eye.style === "sad" ? 5 : 0)

            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }
            Behavior on radius { NumberAnimation { duration: 90 } }
        }

        // the highlight that makes it alive
        Rectangle {
            width: eye.style === "wide" ? 5.5 : 4.5
            height: width
            radius: width / 2
            color: eye.paper
            visible: eye.style === "open" || eye.style === "wide"
            opacity: eye.squint ? 0 : 0.95
            x: (parent.width - width) / 2 + eye.lookX * 3 + 3.5
            y: (parent.height - height) / 2 + eye.lookY * 2 - 4.5

            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }
            Behavior on opacity { NumberAnimation { duration: 90 } }
        }

        // angry: a lid cuts each ball, slanting down towards the middle
        Rectangle {
            visible: eye.style === "angry"
            width: 17
            height: 6
            radius: 3
            color: eye.paper
            rotation: eye.flip ? -14 : 14
            x: (parent.width - width) / 2 + (eye.flip ? 4 : -4)
            y: 1

            Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
        }

        // happy: two little segments meeting up, ^ ^
        Rectangle {
            visible: eye.style === "happy"
            x: 1; y: 9
            width: 12; height: 3.5
            radius: 1.75
            rotation: eye.flip ? -24 : 24
            color: eye.ink
            antialiasing: true
        }
        Rectangle {
            visible: eye.style === "happy"
            x: 13; y: 9
            width: 12; height: 3.5
            radius: 1.75
            rotation: eye.flip ? 24 : -24
            color: eye.ink
            antialiasing: true
        }

        // the tear, only while sad
        Rectangle {
            id: tear
            visible: eye.style === "sad"
            x: eye.flip ? 3 : 19
            width: 4
            height: 5.5
            radius: 2
            color: eye.paper
            y: 18

            SequentialAnimation on y {
                running: tear.visible && face.active
                loops: Animation.Infinite
                NumberAnimation { to: 28; duration: 1100; easing.type: Easing.InQuad }
                NumberAnimation { from: 18; to: 18; duration: 600 }
            }
            SequentialAnimation on opacity {
                running: tear.visible && face.active
                loops: Animation.Infinite
                NumberAnimation { to: 0; duration: 1100 }
                NumberAnimation { to: 0.9; duration: 200 }
            }
        }
    }

    // ===== the card =====
    Item {
        id: card
        anchors.fill: parent

        transformOrigin: Item.Center
        // one wobble knob: press squashes, the animations gelatinize it
        property real wob: 0
        scale: (face.pressed ? 0.96 : 1) * (1 + wob * 0.05)
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
            y: 12
            width: face.cardW - face.pad * 2
            spacing: 7

            // ===== header: dot + banner + bars · provider on the right =====
            Item {
                width: parent.width
                height: 16

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

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

                    Row {
                        id: eq
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        height: 14
                        property real phase: 0

                        FrameAnimation {
                            running: face.active && face.busy
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

            // ===== the face: just two bolitas (and a couple of z's asleep) =====
            Item {
                width: parent.width
                height: 46

                // Glyph pulse halo behind the eyes while thinking or talking
                Rectangle {
                    anchors.centerIn: parent
                    width: 86
                    height: 38
                    radius: 19
                    color: face.accent
                    opacity: face.busy ? (face.streaming ? 0.16 : 0.10) : 0
                    visible: opacity > 0.01

                    Behavior on opacity { NumberAnimation { duration: 280 } }

                    SequentialAnimation on scale {
                        running: face.busy && face.active
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.94; to: 1.08; duration: 680; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.08; to: 0.94; duration: 680; easing.type: Easing.InOutQuad }
                    }
                }

                Bolita {
                    x: (parent.width - width) / 2 - 29
                    y: (parent.height - height) / 2
                    style: face.eyeStyle
                    flip: false
                    lookX: face.lookOf(0).x
                    lookY: face.lookOf(0).y
                    ink: face.mt.ink
                    paper: face.mt.surface
                }
                Bolita {
                    x: (parent.width - width) / 2 + 3
                    y: (parent.height - height) / 2
                    style: face.eyeStyle
                    flip: true
                    lookX: face.lookOf(1).x
                    lookY: face.lookOf(1).y
                    ink: face.mt.ink
                    paper: face.mt.surface
                }

                // drifting z's, only asleep
                Text {
                    visible: face.eyeStyle === "sleep"
                    x: parent.width / 2 + 34
                    y: 2
                    text: "z"
                    color: face.mt.inkSub
                    font.family: face.mt.fontDisplay
                    font.pixelSize: 13

                    SequentialAnimation on y {
                        running: visible && face.active
                        loops: Animation.Infinite
                        NumberAnimation { to: -4; duration: 1600; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 6; to: 6; duration: 300 }
                    }
                    SequentialAnimation on opacity {
                        running: visible && face.active
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 1600 }
                        NumberAnimation { to: 0.9; duration: 300 }
                    }
                }
                Text {
                    visible: face.eyeStyle === "sleep"
                    x: parent.width / 2 + 46
                    y: 14
                    text: "z"
                    color: face.mt.inkSub
                    font.family: face.mt.fontDisplay
                    font.pixelSize: 9

                    SequentialAnimation on y {
                        running: visible && face.active
                        loops: Animation.Infinite
                        NumberAnimation { to: 4; duration: 1600; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 16; to: 16; duration: 300 }
                    }
                    SequentialAnimation on opacity {
                        running: visible && face.active
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 1600 }
                        NumberAnimation { to: 0.7; duration: 300 }
                    }
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

            // model line, or — when the assistant proposed a command — the
            // Ejecutar key in its slot (logs in ai-runs.log; nothing ran
            // until this was pressed)
            Item {
                width: parent.width
                height: 22

                Text {
                    visible: face.pendingRun === ""
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    text: face.speech !== "" ? AiService.model : "doble toque abre el chat · muévela desde Edit Desktop"
                    color: face.mt.inkSub
                    opacity: 0.65
                    font.family: face.mt.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    readonly property bool flash: face.runFlash > 0

                    visible: face.pendingRun !== ""
                    width: parent.width
                    height: 22
                    radius: 11
                    color: flash ? face.mt.surfaceDivider : face.accent

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        visible: !parent.flash
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▶ Ejecutar su propuesta"
                        color: "#ffffff"
                        font.family: face.mt.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.ExtraBold
                    }
                    Text {
                        visible: parent.flash
                        anchors.centerIn: parent
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        text: face.pendingRun.length > 34
                            ? face.pendingRun.slice(0, 33) + "… ✓" : face.pendingRun + " ✓"
                        color: face.mt.ink
                        font.family: face.mt.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (face.runFlash > 0) return
                            AiService.runCommand(face.pendingRun)
                            face.runFlash = 1
                            runFlashTimer.restart()
                        }
                    }
                }
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

        // the happy bounce, and the startle pop — one wobble knob, gelatinous
        SequentialAnimation {
            id: bounce
            NumberAnimation { target: card; property: "wob"; to: 1; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "wob"; to: 0; duration: 480; easing.type: Easing.OutElastic; easing.amplitude: 1.2 }
        }
        SequentialAnimation {
            id: pop
            NumberAnimation { target: card; property: "wob"; to: 1.3; duration: 80; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "wob"; to: 0; duration: 520; easing.type: Easing.OutElastic; easing.amplitude: 1.4 }
        }
    }
}
