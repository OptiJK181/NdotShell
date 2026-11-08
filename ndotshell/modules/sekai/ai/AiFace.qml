import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// AiFace — the kitten card. The Now Playing widget's clothes (Pill housing,
// header with a breathing red dot, THINKING / TYPING / ERROR / IDLE banner,
// dancing bars) around a little cat: dot-matrix ears, big round eyes with a
// highlight, whiskers and a tiny ω mouth. The eyes follow the pointer, blink
// by squashing, and wear the mood the reply leaves behind — happy arcs ^ ^
// with perked ears, droopy eyes and a falling tear when it could not help,
// X-eyes on an error, squinted shut in sleep. The words arrive where the
// track title would sit, in fontDisplay (Ndot 55 on the Nothing theme), and
// under them the ask row: type and Enter sends the question from the card.
//
// Everything here is design pixels: the widget (AiWidget.qml) hosts this
// inside a ScaleHost and owns the window, the drag and the chat drawer. The
// mood is AiService's business (faceMood); `ipc call ai face happy` pins one.
// When `active` is false (Focus Mode hid the card) every timer stops: a
// hidden kitten costs nothing.
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
    readonly property int cardH: 212
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
    property string eyeStyle: "open" // open | happy | sad | x | sleep | wide
    property real runFlash: 0

    Timer {
        id: runFlashTimer
        interval: 2500
        onTriggered: face.runFlash = 0
    }

    readonly property string shownMood: dragging ? "happy"
        : (pressed ? "startle"
        : (drowsy && mood === "neutral" && !hasPointer ? "sleepy" : mood))
    onShownMoodChanged: applyMood()
    Component.onCompleted: applyMood()

    // The banner, Now Playing style: what the model is up to right now.
    readonly property string banner: busy
        ? (streaming ? "TYPING" : "THINKING")
        : (AiService.error !== "" ? "ERROR" : "IDLE")

    function applyMood() {
        seqIndex = 0
        blinking = false
        switch (shownMood) {
        case "thinking":
            // the gaze circles, like thoughts going round
            eyeStyle = "open"
            seq = [{x: -1, y: -1}, {x: 0, y: -1}, {x: 1, y: -1}, {x: 1, y: 0},
                   {x: 1, y: 1}, {x: 0, y: 1}, {x: -1, y: 1}, {x: -1, y: 0}]
            seqTimer.interval = 220
            break
        case "talking":
            // quick glances, the words are coming out
            eyeStyle = "open"
            seq = [{x: 0, y: 0}, {x: 0, y: -1}, {x: 0, y: 1}, {x: 0, y: -1}]
            seqTimer.interval = 200
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
        case "ouch":
            eyeStyle = "x"
            break
        case "sleepy":
            eyeStyle = "sleep"
            lookX = 0
            lookY = 0
            break
        case "startle":
            eyeStyle = "wide"
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
        const cy = cardH * 0.36
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
    readonly property string headline: speech !== "" ? speech : "Miau. ¿En qué te ayudo?"
    readonly property string pendingRun: AiService.lastRunBlocks.length > 0
        ? AiService.lastRunBlocks[AiService.lastRunBlocks.length - 1] : ""

    // ===== the ask row =====
    function sendQuestion() {
        const t = askInput.text.trim()
        if (t === "") return
        if (face.busy) return   // the kitten is talking: keep your text
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
        running: face.active && (face.shownMood === "neutral" || face.shownMood === "curious")
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
        running: face.active && face.shownMood === "neutral" && !face.following && !face.pressed
        onTriggered: face.drowsy = true
    }

    // ===== one kitten eye: a round ball with a highlight, or its mood shape =====
    component CatEye: Item {
        id: eye
        property string style: "open"
        property int lookX: 0
        property int lookY: 0
        property color ink
        property color paper

        readonly property bool round: style === "open" || style === "wide" || style === "sad"
        readonly property bool squint: face.blinking && round

        width: 22
        height: 26

        Item {
            id: globe
            anchors.centerIn: parent
            width: 22
            height: 26

            // the glance: the whole eye shifts a couple of pixels
            transform: Translate {
                x: eye.lookX * 2.5
                y: eye.lookY * 2 + (eye.style === "sad" ? 3 : 0)
            }
            scale: eye.style === "wide" ? 1.2 : 1

            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

            // the ball: squashes to a line for a blink
            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: eye.squint ? 3 : 16
                radius: eye.squint ? 1.5 : 7
                color: eye.ink
                visible: eye.round

                Behavior on height { NumberAnimation { duration: 70 } }
                Behavior on radius { NumberAnimation { duration: 70 } }
            }

            // the highlight that makes it alive
            Rectangle {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 3
                anchors.verticalCenterOffset: -4
                width: 4
                height: 4
                radius: 2
                color: eye.paper
                visible: eye.style === "open" || eye.style === "wide"
                opacity: eye.squint ? 0 : 0.95
            }

            // happy: two little segments meeting up, ^ ^
            Rectangle {
                visible: eye.style === "happy"
                x: 0; y: 11
                width: 10; height: 3
                radius: 1.5
                rotation: 24
                color: eye.ink
                antialiasing: true
            }
            Rectangle {
                visible: eye.style === "happy"
                x: 12; y: 11
                width: 10; height: 3
                radius: 1.5
                rotation: -24
                color: eye.ink
                antialiasing: true
            }

            // ouch: an X
            Rectangle {
                visible: eye.style === "x"
                anchors.centerIn: parent
                width: 15; height: 3
                radius: 1.5
                rotation: 45
                color: eye.ink
                antialiasing: true
            }
            Rectangle {
                visible: eye.style === "x"
                anchors.centerIn: parent
                width: 15; height: 3
                radius: 1.5
                rotation: -45
                color: eye.ink
                antialiasing: true
            }

            // asleep: a shut lid, gently breathing
            Rectangle {
                visible: eye.style === "sleep"
                anchors.centerIn: parent
                width: 14; height: 3
                radius: 1.5
                color: eye.ink

                SequentialAnimation on opacity {
                    running: eye.style === "sleep" && face.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.55; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 1400; easing.type: Easing.InOutSine }
                }
            }

            // the tear, only while sad
            Rectangle {
                id: tear
                visible: eye.style === "sad"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 8
                width: 3.5
                height: 5
                radius: 1.75
                color: eye.paper
                y: 16

                SequentialAnimation on y {
                    running: tear.visible && face.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 26; duration: 1100; easing.type: Easing.InQuad }
                    NumberAnimation { from: 16; to: 16; duration: 500 }
                }
                SequentialAnimation on opacity {
                    running: tear.visible && face.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: 1100 }
                    NumberAnimation { to: 0.9; duration: 200 }
                }
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
            y: 12
            width: face.cardW - face.pad * 2
            spacing: 6

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

            // ===== the kitten: ears, eyes, nose, whiskers, mouth =====
            Item {
                width: parent.width
                height: 66

                // the eye line sits here
                readonly property real eyeY: 30
                readonly property real eyeOff: 17

                // dot-matrix ears; they perk when the kitten is happy
                Repeater {
                    model: [
                        { xc: (parent.width / 2) - parent.eyeOff, tilt: -8 },
                        { xc: (parent.width / 2) + parent.eyeOff, tilt: 8 }
                    ]

                    delegate: Item {
                        required property var modelData
                        x: modelData.xc - 9
                        y: 1
                        width: 18
                        height: 17
                        rotation: face.eyeStyle === "happy" ? modelData.tilt : 0

                        Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }

                        Repeater {
                            model: [{ r: 0, n: 1 }, { r: 1, n: 2 }, { r: 2, n: 3 }]

                            delegate: Row {
                                required property var modelData
                                x: (parent.width - modelData.n * 4.5 - (modelData.n - 1) * 1.5) / 2
                                y: modelData.r * 5.5
                                spacing: 1.5

                                Repeater {
                                    model: modelData.n

                                    delegate: Rectangle {
                                        width: 4.5
                                        height: 4.5
                                        radius: 2.25
                                        color: face.mt.ink
                                    }
                                }
                            }
                        }
                    }
                }

                CatEye {
                    x: (parent.width - width) / 2 - parent.eyeOff
                    y: parent.eyeY
                    style: face.eyeStyle
                    lookX: face.lookOf(0).x
                    lookY: face.lookOf(0).y
                    ink: face.mt.ink
                    paper: face.mt.surface
                }
                CatEye {
                    x: (parent.width - width) / 2 + parent.eyeOff - width
                    y: parent.eyeY
                    style: face.eyeStyle
                    lookX: face.lookOf(1).x
                    lookY: face.lookOf(1).y
                    ink: face.mt.ink
                    paper: face.mt.surface
                }

                // the nose: one tiny accent dot
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.eyeY + 19
                    width: 4.5
                    height: 4
                    radius: 2
                    color: face.accent
                }

                // the mouth: a little ω, wider when happy, a frown when sad
                Item {
                    id: mouth
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.eyeY + 26
                    width: 20
                    height: 8

                    scale: face.eyeStyle === "happy" ? 1.25 : 1
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                    Repeater {
                        model: face.eyeStyle === "sad"
                            ? [{x: -8, y: 4}, {x: -4, y: 1}, {x: 0, y: 1}, {x: 4, y: 1}, {x: 8, y: 4}]
                            : [{x: -8, y: 1}, {x: -4, y: 4}, {x: 0, y: 1}, {x: 4, y: 4}, {x: 8, y: 1}]

                        delegate: Rectangle {
                            required property var modelData
                            x: parent.width / 2 + modelData.x - 1.5
                            y: modelData.y
                            width: 3
                            height: 3
                            radius: 1.5
                            color: face.mt.ink
                        }
                    }
                }

                // whiskers: three a side, quiet
                Repeater {
                    model: [
                        { side: -1, y: -6 }, { side: -1, y: 0 }, { side: -1, y: 6 },
                        { side: 1, y: -6 }, { side: 1, y: 0 }, { side: 1, y: 6 }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        x: modelData.side < 0
                            ? (parent.width / 2) - parent.eyeOff - 24
                            : (parent.width / 2) + parent.eyeOff + 11
                        y: parent.eyeY + 8 + modelData.y
                        width: 13
                        height: 1.5
                        radius: 0.75
                        color: face.mt.inkSub
                        opacity: 0.55
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

                // the red key: send (grey while the kitten is talking or the
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
