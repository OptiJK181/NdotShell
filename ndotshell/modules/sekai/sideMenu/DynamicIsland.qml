import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Dynamic Island — menú interactivo vertical en el lateral derecho: del
// medio del borde hasta la esquina inferior derecha. 100% manual (Super +
// Shift + D o ipc call island toggle). En su cabeza, un agujero negro
// girando (núcleo negro, disco de acento y satélite en órbita); debajo,
// las llaves del menú: REC · POMODORO · MÚSICA · PRIVADO · CAPTURA ·
// GAMING · FOCUS. Esc lo cierra; el toggle de Ajustes (side.island) lo
// apaga entero.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Math.round(cardW * win.uiScale)
    visible: SettingsService.flag("side.island")
        && (SideMenuService.islandOpen || win.openAnim > 0.001)

    readonly property real cardW: 76

    property real openAnim: SideMenuService.islandOpen ? 1 : 0
    Behavior on openAnim {
        NumberAnimation {
            duration: 640
            easing.type: Easing.OutElastic
            easing.amplitude: 1.25
            easing.period: 0.5
        }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.islandOpen
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    Item {
        id: card

        // del medio del lateral (40%) hasta cerca de la esquina inferior (94%)
        // pegada al borde derecho; el rebote es scale desde el borde
        x: Math.round(win.width - win.cardW * win.uiScale)
        y: Math.round(parent.height * 0.40)
        width: Math.round(win.cardW * win.uiScale)
        height: Math.round(parent.height * 0.54)
        scale: win.openAnim
        opacity: Math.min(1, win.openAnim * 2)
        transformOrigin: Item.Right

        HoverHandler { id: cardHover }

        Keys.onEscapePressed: SideMenuService.islandOpen = false

        // slab
        Rectangle {
            anchors.fill: parent
            radius: 26 * win.uiScale
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder
        }

        // accent hairline on the screen edge
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2 * win.uiScale
            color: mt.nbAccent
            opacity: win.openAnim
        }

        Column {
            anchors.fill: parent
            anchors.topMargin: 18 * win.uiScale
            anchors.bottomMargin: 16 * win.uiScale
            anchors.leftMargin: 12 * win.uiScale
            anchors.rightMargin: 12 * win.uiScale
            spacing: 10 * win.uiScale

            // ===== agujero negro =====
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56 * win.uiScale
                height: 56 * win.uiScale

                // disco de acento girando (arco 270°)
                Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.beginPath()
                            ctx.arc(width / 2, height / 2,
                                Math.min(width, height) / 2 - 4 * win.uiScale,
                                0, Math.PI * 1.55)
                            ctx.strokeStyle = Qt.rgba(mt.nbAccent.r, mt.nbAccent.g, mt.nbAccent.b, 0.95)
                            ctx.lineWidth = 3 * win.uiScale
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }
                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 3200
                        loops: Animation.Infinite
                    }
                }

                // satélite en órbita contraria
                Item {
                    anchors.fill: parent

                    Rectangle {
                        x: parent.width / 2 - 3 * win.uiScale
                        y: -2 * win.uiScale
                        width: 6 * win.uiScale
                        height: 6 * win.uiScale
                        radius: 3 * win.uiScale
                        color: mt.nbInk
                    }
                    RotationAnimation on rotation {
                        from: 360
                        to: 0
                        duration: 2100
                        loops: Animation.Infinite
                    }
                }

                // núcleo
                Rectangle {
                    anchors.centerIn: parent
                    width: 26 * win.uiScale
                    height: 26 * win.uiScale
                    radius: 13 * win.uiScale
                    color: "#000000"
                    border.width: 1
                    border.color: mt.nbInkSub
                }

                property real angle: 0
                property real angle2: 0
            }

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // ===== llaves del menú =====
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10 * win.uiScale

                IslandKey {
                    icon: ScreenRecorderService.recording ? "stop" : "videocam"
                    accent: ScreenRecorderService.recording
                    onClicked: ScreenRecorderService.toggle()
                }

                IslandKey {
                    icon: PomodoroService.running ? "pause" : "play"
                    accent: PomodoroService.running
                    onClicked: PomodoroService.toggle()
                }

                IslandKey {
                    icon: media.playing ? "pause" : "play"
                    accent: media.playing
                    onClicked: media.togglePlaying()
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 24 * win.uiScale
                    height: 1
                    color: mt.nbBorder
                }

                IslandKey {
                    icon: ClipboardHistoryService.privateMode ? "eye-closed" : "eye"
                    accent: ClipboardHistoryService.privateMode
                    onClicked: {
                        const on = ClipboardHistoryService.togglePrivate()
                        OSDSource.showPrivate(on)
                    }
                }

                IslandKey {
                    icon: "crop"
                    onClicked: {
                        SideMenuService.islandOpen = false
                        RegionService.showLater("copy")
                    }
                }

                IslandKey {
                    icon: "sports_esports"
                    accent: SideMenuService.open === "gaming"
                    onClicked: {
                        SideMenuService.islandOpen = false
                        SideMenuService.toggle("gaming")
                    }
                }

                IslandKey {
                    icon: "center_focus_strong"
                    accent: SideMenuService.open === "work"
                    onClicked: {
                        SideMenuService.islandOpen = false
                        SideMenuService.toggle("work")
                    }
                }
            }
        }
    }

    MediaSource { id: media }

    component IslandKey: Rectangle {
        property string icon: ""
        property bool accent: false
        signal clicked()

        width: 42 * win.uiScale
        height: 42 * win.uiScale
        radius: 21 * win.uiScale
        color: keyMa.pressed ? mt.nbBorder : (accent ? mt.nbAccent : mt.nbRaised)
        border.width: 1
        border.color: accent ? mt.nbAccent : mt.nbBorder
        scale: keyMa.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        MaterialIcon {
            anchors.centerIn: parent
            name: parent.icon
            size: 18 * win.uiScale
            color: parent.accent ? "#ffffff" : mt.nbInk
        }

        MouseArea {
            id: keyMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}