import QtQuick
import Quickshell
import qs.modules.common

// A message's text, with ``` fenced code blocks drawn as real code cards.
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
        const re = /```[a-zA-Z0-9_+.-]*\n?([\s\S]*?)```/g
        let last = 0
        let m
        while ((m = re.exec(src)) !== null) {
            if (m.index > last) out.push({ code: false, body: src.slice(last, m.index) })
            out.push({ code: true, body: m[1] })
            last = m.index + m[0].length
        }
        if (last < src.length) out.push({ code: false, body: src.slice(last) })
        if (out.length === 0) out.push({ code: false, body: src })
        return out
    }

    Repeater {
        model: root.parts

        delegate: Item {
            id: block
            width: root.width
            height: modelData.code ? codeCard.height : plain.implicitHeight

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
                height: codeText.implicitHeight + 20
                radius: 10
                color: root.mt.nbSurface
                border.width: 1
                border.color: root.mt.nbBorder

                Text {
                    id: codeText
                    anchors.left: parent.left
                    anchors.right: parent.right
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
            }
        }
    }
}
