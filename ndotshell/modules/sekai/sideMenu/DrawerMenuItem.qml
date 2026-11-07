import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Big-typography menu item — Sekai power-menu style:
//   uppercase italic display text stacked; hover/select slides a skewed
//   wedge in behind and the word turns the channel accent with a small
//   lift (white wedge + red italic word, like the reference shot).
// `selected` pins the wedge (toggles); otherwise it follows hover.
Item {
    id: root

    property string text: ""
    // pinned highlight (toggle-on state)
    property bool selected: false
    // one-shot rows get a chevron
    property bool action: false
    // scale context (the drawer multiplies everything by its uiScale)
    property real s: 1
    // theme wiring from the drawer
    property color inkColor: "#f5f5f5"
    property color subInkColor: "#8f8f8f"
    property color accentColor: "#d71921"
    property string displayFont: "Ndot 55"

    signal activated()

    // aparición escalonada: 0 = fuera, 1 = en sitio (lo maneja el drawer)
    property real appear: 1
    // true = el panel entra desde la derecha (gaming), false desde la izquierda
    property bool fromRight: false

    readonly property bool lit: root.selected || ma.containsMouse

    width: parent ? parent.width : 0
    height: 42 * root.s
    opacity: appear
    transform: Translate { x: (1 - appear) * root.s * (root.fromRight ? 30 : -30) }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // ===== the skewed wedge =====
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: -16 * root.s
        anchors.right: parent.right
        anchors.rightMargin: -8 * root.s
        anchors.verticalCenter: parent.verticalCenter
        height: root.height + 8 * root.s
        radius: 3 * root.s
        color: root.lit ? "#f5f5f5" : "transparent"
        rotation: -3
        opacity: root.lit ? 1 : 0
        x: root.lit ? 0 : -22 * root.s
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
    }

    // ===== the word =====
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8 * root.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.lit ? root.accentColor : root.subInkColor
        font.family: root.displayFont
        font.pixelSize: (root.selected ? 22 : 20) * root.s
        font.italic: true
        font.weight: Font.ExtraBold
        font.letterSpacing: 1.5 * root.s
        x: root.lit ? 10 * root.s : 0
        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on x { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on font.pixelSize { NumberAnimation { duration: 130 } }
    }

    // chevron for one-shot rows
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12 * root.s
        anchors.verticalCenter: parent.verticalCenter
        visible: root.action
        text: "›"
        color: root.lit ? root.accentColor : root.subInkColor
        font.family: root.displayFont
        font.pixelSize: 22 * root.s
        font.italic: true
        font.weight: Font.ExtraBold
        opacity: root.lit ? 1 : 0.35
        Behavior on opacity { NumberAnimation { duration: 130 } }
        Behavior on color { ColorAnimation { duration: 130 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.leftMargin: -12 * root.s
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}