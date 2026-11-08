import QtQuick
import Quickshell
import qs.modules.common

// A message's text, with ``` fenced code blocks drawn as real code cards.
// A ```run``` block is special: the command the assistant proposes for the
// computer, with a red Ejecutar key on the card — nothing runs until the
// person presses it (scripts/ai/ai-run.sh is the only door, and it logs).
// Inline `code` stays as written (the model's markdown is not interpreted
// beyond fences on purpose: no surprises, no broken layouts).
Column {
    id: root

    property string text: ""
    readonly property string monoFamily: "JetBrainsMonoNL Nerd Font"
    readonly property var mt: Theme.of(QsWindow.window)

    spacing: 8

    readonly property var parts: {
        const out = []
        const src = root.text
        const re = /```([a-zA-Z0-9_+.-]*)\n?([\s\S]*?)```/g
        let last = 0
        let m
        while ((m = re.exec(src)) !== null) {
            if (m.index > last) out.push({ code: false, lang: "", body: src.slice(last, m.index) })
            out.push({ code: true, lang: m[1] || "", body: m[2] })
            last = m.index + m[0].length
        }
        if (last < src.length) out.push({ code: false, lang: "", body: src.slice(last) })
        if (out.length === 0) out.push({ code: false, lang: "", body: src })
        return out
    }

    Repeater {
        model: root.parts

        delegate: Item {
            id: block
            width: root.width
            height: modelData.code ? codeCard.height : plain.implicitHeight
            readonly property bool isRun: modelData.lang === "run"
            // one-shot flash after pressing Ejecutar
            property real flash: 0

            Timer {
                id: flashTimer
                interval: 2000
                onTriggered: block.flash = 0
            }

            Text {
                id: plain
                visible: !modelData.code
                width: parent.width
                text: modelData.body.trim()
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: root.mt.nbInk
                font.family: root.mt.fontFamily
                font.pixelSize: 15
                lineHeight: 1.25
            }

            Rectangle {
                id: codeCard
                visible: modelData.code
                width: parent.width
                height: Math.max(codeText.implicitHeight + 20, 44)
                radius: 10
                color: root.mt.nbSurface
                border.width: 1
                border.color: modelData.lang === "run" ? root.mt.nbAccent : root.mt.nbBorder

                Text {
                    id: codeText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: block.isRun ? 96 : 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 10
                    text: modelData.body.replace(/\s+$/, "")
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                    color: root.mt.nbInk
                    font.family: root.monoFamily
                    font.pixelSize: 13
                    lineHeight: 1.2
                }

                // the Ejecutar key, only on a ```run``` block: the command
                // does nothing until this is pressed
                Rectangle {
                    readonly property bool done: block.flash > 0
                    visible: block.isRun
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: done ? 84 : 80
                    height: 30
                    radius: 15
                    color: done ? root.mt.nbSurface : root.mt.nbAccent

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: parent.done ? "corriendo ✓" : "▶ Ejecutar"
                        color: parent.done ? root.mt.nbInk : "#ffffff"
                        font.family: root.mt.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.ExtraBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (block.flash > 0) return
                            AiService.runCommand(modelData.body)
                            block.flash = 1
                            flashTimer.restart()
                        }
                    }
                }
            }
        }
    }
}
