import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.sideMenu

// Work drawer (ofimática) — Caelestia hotspot on the left edge; Sekai
// power-menu typography inside. Pomodoro card + menu: Focus Mode,
// clipboard privacy, Notas / To-Do / Calendario toggles.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; left: true }
    implicitWidth: Math.round(cardW * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 330

    property real slide: SideMenuService.open === "work"
        && SettingsService.flag("side.work") ? 1 : 0
    Behavior on slide { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    visible: win.slide > 0.001
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.open === "work"
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    Item {
        id: card

        x: Math.round(-win.cardW * win.uiScale * (1 - win.slide))
        y: 0
        width: Math.round(win.cardW * win.uiScale)
        height: win.height

        HoverHandler { id: cardHover }
        Binding { target: SideMenuService; property: "cardHovered"; value: cardHover.hovered }

        focus: SideMenuService.open === "work"
        Keys.onEscapePressed: SideMenuService.hide()

        Rectangle {
            anchors.fill: parent
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder
        }

        // accent hairline on the screen edge
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2 * win.uiScale
            color: mt.nbAccent
            opacity: win.slide
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 22 * win.uiScale
            anchors.rightMargin: 22 * win.uiScale
            anchors.topMargin: 24 * win.uiScale
            anchors.bottomMargin: 18 * win.uiScale
            spacing: 10 * win.uiScale

            // ===== header =====
            Item {
                width: parent.width
                height: 46 * win.uiScale

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: qsTr("FOCUS")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 26 * win.uiScale
                        font.letterSpacing: 7 * win.uiScale
                    }

                    Text {
                        text: qsTr("OFIMÁTICA")
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 9 * win.uiScale
                        font.letterSpacing: 3 * win.uiScale
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: SideMenuService.pinned === "work"
                    width: pinText.implicitWidth + 16 * win.uiScale
                    height: 22 * win.uiScale
                    radius: 11 * win.uiScale
                    color: "transparent"
                    border.width: 1
                    border.color: mt.nbBorder
                    Text {
                        id: pinText
                        anchors.centerIn: parent
                        text: qsTr("FIJADO")
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 9 * win.uiScale
                        font.letterSpacing: 2 * win.uiScale
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // ===== Pomodoro card (label can never touch the border) =====
            Rectangle {
                width: parent.width
                height: 186 * win.uiScale
                radius: 14 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: PomodoroService.running ? mt.accentCyan : mt.nbBorder

                Column {
                    anchors.centerIn: parent
                    spacing: 7 * win.uiScale

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PomodoroService.stateLabel
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 11 * win.uiScale
                        font.letterSpacing: 3 * win.uiScale
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PomodoroService.format()
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 50 * win.uiScale
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10 * win.uiScale

                        RoundWorkKey {
                            icon: PomodoroService.running ? "pause" : "play"
                            onClicked: PomodoroService.toggle()
                        }
                        RoundWorkKey {
                            icon: "skip-next"
                            visible: !PomodoroService.idle
                            onClicked: PomodoroService.skip()
                        }
                        RoundWorkKey {
                            icon: "refresh"
                            onClicked: PomodoroService.reset()
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("%1 ciclos hoy · %2 min")
                              .arg(PomodoroService.completedCycles)
                              .arg(Math.floor(PomodoroService.totalWorkTime / 60))
                        color: mt.nbInkSub
                        font.pixelSize: 11 * win.uiScale
                    }
                }
            }

            // ===== the menu =====
            DrawerMenuItem {
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("FOCUS MODE")
                selected: FocusService.enabled
                onActivated: SettingsService.toggle("focus.enabled")
            }

            DrawerMenuItem {
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("MODO PRIVADO")
                selected: ClipboardHistoryService.privateMode
                onActivated: {
                    const on = ClipboardHistoryService.togglePrivate()
                    OSDSource.showPrivate(on)
                }
            }

            DrawerMenuItem {
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                action: true
                text: qsTr("BORRAR HISTORIAL")
                onActivated: ClipboardHistoryService.wipe()
            }

            DrawerMenuItem {
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("NOTAS")
                selected: NotesService.shown
                onActivated: NotesService.setShown(!NotesService.shown)
            }

            DrawerMenuItem {
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("TO-DO")
                selected: TodoService.shown
                onActivated: TodoService.setShown(!TodoService.shown)
            }

            DrawerMenuItem {
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("CALENDARIO")
                selected: CalendarCardService.shown
                onActivated: CalendarCardService.setShown(!CalendarCardService.shown)
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: qsTr("Toca el borde izquierdo para abrir · Esc cierra")
                color: mt.nbInkSub
                font.pixelSize: 11 * win.uiScale
            }
        }
    }

    component RoundWorkKey: Rectangle {
        property string icon: ""
        signal clicked()

        width: 44 * win.uiScale
        height: 44 * win.uiScale
        radius: 22 * win.uiScale
        color: keyMa.pressed ? mt.nbBorder : mt.nbSurface
        border.width: 1
        border.color: mt.nbBorder

        MaterialIcon {
            anchors.centerIn: parent
            name: parent.icon
            size: 20 * win.uiScale
            color: mt.nbInk
        }

        MouseArea {
            id: keyMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}