import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Dynamic Island — full height en el lado derecho, menú abajo.
// 100% manual (Super + Shift + D o ipc island toggle).
PanelWindow {
    id: win

    required property var modelData
    screen: modelData
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; right: true }
    implicitWidth: Math.round(cardW * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

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

    visible: SettingsService.flag("side.island")
        && (SideMenuService.islandOpen || win.openAnim > 0.001)
    WlrLayershell.layer: WlrLayer.Top

    mask: Region { item: card }

    Item {
        id: card

        x: Math.round((1 - Math.min(1.18, Math.max(0, win.openAnim))) * parent.width)
        // abajo: desde el 40% de la pantalla hasta casi el fondo
        y: Math.round(parent.height * 0.40)
        width: Math.round(parent.width)
        height: Math.round(parent.height * 0.55)

        Keys.onEscapePressed: SideMenuService.islandOpen = false

        opacity: Math.min(1.0, Math.max(0, win.openAnim))

        // slab
        Rectangle {
            anchors.fill: parent
            radius: 20 * win.uiScale
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder

            Rectangle {
                visible: ScreenRecorderService.recording
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: mt.nbAccent
            }
        }

        // ✕ close
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8 * win.uiScale
            width: 22 * win.uiScale
            height: 22 * win.uiScale
            radius: 11 * win.uiScale
            color: xMa.pressed ? mt.nbBorder : mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: mt.nbInk
                font.pixelSize: 11 * win.uiScale
            }

            MouseArea {
                id: xMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: SideMenuService.islandOpen = false
            }
        }

        Column {
            anchors.fill: parent
            anchors.topMargin: 12 * win.uiScale
            anchors.bottomMargin: 12 * win.uiScale
            anchors.leftMargin: 10 * win.uiScale
            anchors.rightMargin: 10 * win.uiScale
            spacing: 8 * win.uiScale

            // agujero negro
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 48 * win.uiScale
                height: 48 * win.uiScale

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
                        duration: AiService.busy ? 1200 : 3200
                        loops: Animation.Infinite
                    }
                }

                Item {
                    anchors.fill: parent

                    Rectangle {
                        x: parent.width / 2 - 3 * win.uiScale
                        y: -2 * win.uiScale
                        width: 5 * win.uiScale
                        height: 5 * win.uiScale
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

                Rectangle {
                    anchors.centerIn: parent
                    width: 22 * win.uiScale
                    height: 22 * win.uiScale
                    radius: 11 * win.uiScale
                    color: "#000000"
                    border.width: 1
                    border.color: mt.nbInkSub
                }
            }

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // llaves
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8 * win.uiScale

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
                    width: 20 * win.uiScale
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
                    icon: "stars"
                    accent: AiService.busy || AiService.drawerOpen
                    onClicked: {
                        SideMenuService.islandOpen = false
                        AiService.toggle()
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

        width: 36 * win.uiScale
        height: 36 * win.uiScale
        radius: 18 * win.uiScale
        color: keyMa.pressed ? mt.nbBorder : (accent ? mt.nbAccent : (keyMa.containsMouse ? (mt.nbRaisedHover || Qt.lighter(mt.nbRaised, 1.15)) : mt.nbRaised))
        border.width: 1
        border.color: accent ? mt.nbAccent : (keyMa.containsMouse ? mt.nbInkSub : mt.nbBorder)
        scale: keyMa.pressed ? 0.90 : (keyMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        MaterialIcon {
            anchors.centerIn: parent
            name: parent.icon
            size: 16 * win.uiScale
            color: parent.accent ? "#ffffff" : mt.nbInk
        }

        MouseArea {
            id: keyMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}