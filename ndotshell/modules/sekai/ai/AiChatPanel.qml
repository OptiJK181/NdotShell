import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The AI conversation, in the shell's Nothing dress. One component, three
// surfaces: the side drawer, the bar popup and the desktop orb all show this.
//
// Everything lives in AiService: sending, streaming, history, errors. This
// file only draws it and keeps the list pinned to the last message.
Item {
    id: panel

    property bool showClose: true
    property bool active: true
    signal closeRequested()

    readonly property var mt: Theme.of(QsWindow.window)
    readonly property var suggestions: [
        "¿Qué puedo hacer con NdotShell?",
        "Explícame un comando de Hyprland",
        "Ayúdame a escribir un script",
        "Dame ideas para mi escritorio"
    ]

    function submit() {
        const text = input.text
        if (text.trim() === "") return
        input.text = ""
        AiService.send(text)
    }

    function focusInput() {
        if (panel.active) Qt.callLater(() => input.forceActiveFocus())
    }

    onActiveChanged: if (active) focusInput()
    Component.onCompleted: focusInput()

    Connections {
        target: AiService
        function onMessagesChanged() { Qt.callLater(list.positionViewAtEnd) }
        function onStreamingTextChanged() { Qt.callLater(list.positionViewAtEnd) }
        function onDrawerOpenChanged() { if (AiService.drawerOpen) panel.focusInput() }
    }

    Keys.onEscapePressed: {
        if (AiService.busy) AiService.stop()
        else panel.closeRequested()
    }

    // ---- body ----
    Rectangle {
        anchors.fill: parent
        radius: 26
        color: panel.mt.nbSurface
        border.width: 1
        border.color: panel.mt.nbBorder
    }

    // ===== header =====
    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 16
        anchors.topMargin: 18
        height: 42

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Text {
                text: "NDOT"
                color: panel.mt.nbInk
                font.family: panel.mt.fontDisplay
                font.pixelSize: 23
                font.letterSpacing: 6
            }
            Text {
                text: "AI"
                color: panel.mt.nbAccent
                font.family: panel.mt.fontDisplay
                font.pixelSize: 23
                font.letterSpacing: 4
            }
        }

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: Math.max(0, parent.width - actions.width - 16)
            text: AiService.busy
                ? "generando…"
                : (AiService.providerLabel + " · " + (AiService.model !== "" ? AiService.model : "sin modelo"))
            color: panel.mt.nbInkSub
            font.family: panel.mt.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            AiIconButton {
                icon: "content_copy"
                tip: "Copiar la última respuesta"
                visible: AiService.lastAssistant !== null
                onClicked: AiService.copyLast()
            }
            AiIconButton {
                icon: "delete"
                tip: "Borrar la conversación"
                danger: true
                visible: AiService.messages.length > 0
                onClicked: AiService.clear()
            }
            AiIconButton {
                icon: "close"
                tip: "Cerrar"
                visible: panel.showClose
                onClicked: panel.closeRequested()
            }
        }
    }

    Rectangle {
        id: divider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 12
        height: 1
        color: panel.mt.nbBorder
    }

    // ===== conversation =====
    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: divider.bottom
        anchors.bottom: errorBox.visible ? errorBox.top : inputArea.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 10
        clip: true
        spacing: 12
        model: AiService.messages
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 400

        delegate: Item {
            id: messageRow
            required property var modelData
            required property int index

            readonly property bool mine: modelData.role === "user"

            width: list.width
            height: messageColumn.height

            TextMetrics {
                id: measure
                font.family: panel.mt.fontFamily
                font.pixelSize: 15
                text: messageRow.modelData.content
            }

            Column {
                id: messageColumn
                width: messageRow.mine
                    ? Math.min(messageRow.width * 0.82, Math.max(120, measure.advanceWidth + 28))
                    : messageRow.width * 0.94
                anchors.right: messageRow.mine ? parent.right : undefined
                anchors.left: messageRow.mine ? undefined : parent.left
                spacing: 4

                Row {
                    width: parent.width
                    layoutDirection: messageRow.mine ? Qt.RightToLeft : Qt.LeftToRight
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: messageRow.mine ? "TÚ" : "NDOT"
                        color: messageRow.mine ? panel.mt.nbInkSub : panel.mt.nbAccent
                        font.family: panel.mt.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.ExtraBold
                        font.letterSpacing: 2
                    }

                    AiIconButton {
                        width: 22
                        height: 22
                        icon: "content_copy"
                        visible: !messageRow.mine
                        onClicked: Quickshell.execDetached(["wl-copy", messageRow.modelData.content])
                    }
                }

                Rectangle {
                    width: parent.width
                    height: body.height + 24
                    radius: 16
                    color: messageRow.mine ? panel.mt.nbAccent : panel.mt.nbRaised
                    border.width: messageRow.mine ? 0 : 1
                    border.color: panel.mt.nbBorder

                    AiMessageBody {
                        id: body
                        x: 12
                        y: 12
                        width: parent.width - 24
                        text: messageRow.modelData.content
                    }
                }
            }
        }

        // What is being written right now, plus the cursor.
        footer: Item {
            width: list.width
            height: AiService.busy ? streamBubble.height + 12 : 0

            Rectangle {
                id: streamBubble
                width: Math.min(parent.width * 0.94, parent.width)
                height: streamColumn.height + 24
                radius: 16
                color: panel.mt.nbRaised
                border.width: 1
                border.color: panel.mt.nbBorder

                Column {
                    id: streamColumn
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 6

                    Row {
                        spacing: 6

                        Text {
                            text: "NDOT"
                            color: panel.mt.nbAccent
                            font.family: panel.mt.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.ExtraBold
                            font.letterSpacing: 2
                        }

                        Item {
                            width: 7
                            height: 7
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent
                                radius: 3.5
                                color: panel.mt.nbAccent
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.2; duration: 520; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 1.0; duration: 520; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }

                    AiMessageBody {
                        width: parent.width
                        text: AiService.streamingText !== ""
                            ? AiService.streamingText
                            : "pensando…"
                    }
                }
            }
        }
    }

    WheelScroll { scroller: list }

    // Empty conversation: what this thing is for, and a few openers.
    Item {
        anchors.fill: list
        visible: AiService.messages.length === 0 && !AiService.busy

        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - 24, 360)
            spacing: 12

            Text {
                width: parent.width
                text: "¿EN QUÉ PIENSAS?"
                color: panel.mt.nbInk
                font.family: panel.mt.fontDisplay
                font.pixelSize: 22
                font.letterSpacing: 3
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: AiService.configured
                    ? "Pregunta lo que sea. La conversación se queda en este equipo."
                    : "Configura tu proveedor en Ajustes → Inteligencia Artificial."
                color: AiService.configured ? panel.mt.nbInkSub : panel.mt.nbAccent
                font.family: panel.mt.fontFamily
                font.pixelSize: 13
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                width: parent.width
                spacing: 7

                Repeater {
                    model: panel.suggestions

                    delegate: Rectangle {
                        required property string modelData
                        width: parent.width
                        height: 36
                        radius: 12
                        color: suggestionMouse.containsMouse ? panel.mt.nbRaised : "transparent"
                        border.width: 1
                        border.color: panel.mt.nbBorder

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            text: modelData
                            color: panel.mt.nbInkSub
                            font.family: panel.mt.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            id: suggestionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!AiService.configured) {
                                    AiService.error = "Falta configurar el proveedor (Ajustes → Inteligencia Artificial)."
                                    return
                                }
                                AiService.send(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ===== error =====
    Rectangle {
        id: errorBox
        visible: AiService.error !== ""
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: inputArea.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 8
        height: errorColumn.height + 18
        radius: 12
        color: "#1c0d0e"
        border.width: 1
        border.color: panel.mt.nbAccent

        Column {
            id: errorColumn
            x: 12
            y: 9
            width: parent.width - 24
            spacing: 2

            Text {
                width: parent.width
                text: "ERROR"
                color: panel.mt.nbAccent
                font.family: panel.mt.fontFamily
                font.pixelSize: 9
                font.weight: Font.ExtraBold
                font.letterSpacing: 2
            }
            Text {
                width: parent.width
                text: AiService.error
                color: panel.mt.nbInk
                font.family: panel.mt.fontFamily
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }

    // ===== input =====
    Rectangle {
        id: inputArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 18
        height: 56
        radius: 18
        color: panel.mt.nbRaised
        border.width: 1
        border.color: input.activeFocus ? panel.mt.nbAccent : panel.mt.nbBorder

        TextInput {
            id: input
            anchors.left: parent.left
            anchors.right: sendButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 15
            anchors.rightMargin: 8
            clip: true
            selectByMouse: true
            color: panel.mt.nbInk
            selectionColor: panel.mt.nbAccent
            selectedTextColor: "#ffffff"
            font.family: panel.mt.fontFamily
            font.pixelSize: 15
            onAccepted: panel.submit()
            Keys.onEscapePressed: {
                if (AiService.busy) AiService.stop()
                else panel.closeRequested()
            }

            Text {
                visible: input.text === "" && !input.activeFocus
                anchors.verticalCenter: parent.verticalCenter
                text: AiService.configured ? "Pregúntale algo a Ndot…" : "Configura el proveedor en Ajustes"
                color: panel.mt.nbInkSub
                font: input.font
            }
        }

        Rectangle {
            id: sendButton
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            radius: 20
            color: AiService.busy
                ? panel.mt.nbAccent
                : (input.text.trim() !== "" && AiService.configured ? panel.mt.nbAccent : panel.mt.nbSurface)
            border.width: AiService.busy || (input.text.trim() !== "" && AiService.configured) ? 0 : 1
            border.color: panel.mt.nbBorder
            opacity: (input.text.trim() !== "" || AiService.busy) ? 1 : 0.55

            MaterialIcon {
                anchors.centerIn: parent
                visible: !AiService.busy
                name: "arrow_upward"
                size: 18
                color: (input.text.trim() !== "" && AiService.configured) ? "#ffffff" : panel.mt.nbInkSub
            }

            Rectangle {
                anchors.centerIn: parent
                visible: AiService.busy
                width: 12
                height: 12
                radius: 3
                color: "#ffffff"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (AiService.busy) AiService.stop()
                    else panel.submit()
                }
            }
        }
    }
}
