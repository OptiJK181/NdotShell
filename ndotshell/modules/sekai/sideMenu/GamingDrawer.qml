import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Gaming drawer — Caelestia-style: a thin hotspot strip runs down the RIGHT
// edge; hover it and the panel slides out; move away and it slides back.
// A keybind (Super + Shift + G) or `ipc call sidemenu gaming` pins it open.
// 100% gaming: Game Mode, recorder with live timer, notifications off,
// Keep Awake, CPU/RAM meters.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    property var qsSource
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; right: true }
    // The window is only the strip + the card width; invisible (unmapped)
    // while fully closed, so idle cost is zero.
    implicitWidth: Math.round((cardW + hotW) * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 320
    readonly property real hotW: 8

    // 0 = hidden, 1 = fully out.
    property real slide: SideMenuService.open === "gaming" ? 1 : 0
    Behavior on slide { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    visible: SideMenuService.open === "gaming" || win.slide > 0.001
        || hotspot.containsMouse
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.open === "gaming"
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Only the card (and the hotspot strip) take input.
    mask: Region { item: card }

    // ===== edge hotspot: hover the last pixels of the screen =====
    MouseArea {
        id: hotspot
        x: Math.round(win.width - win.hotW * win.uiScale)
        y: 0
        width: Math.ceil(win.hotW * win.uiScale)
        height: win.height
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse) SideMenuService.hoverEnter("gaming")
            else SideMenuService.hoverLeave()
        }
        // A tap on the edge also opens (touchscreens / trackpad taps).
        onClicked: SideMenuService.toggle("gaming")
    }

    // ===== the card =====
    Item {
        id: card

        // From fully hidden (right edge + the hotspot strip) to fully out.
        x: Math.round(win.width - win.cardW * win.uiScale * win.slide)
        y: 0
        width: Math.round(win.cardW * win.uiScale)
        height: win.height

        HoverHandler { id: cardHover }
        Binding { target: SideMenuService; property: "cardHovered"; value: cardHover.hovered }

        focus: SideMenuService.open === "gaming"
        Keys.onEscapePressed: SideMenuService.hide()

        // ===== slab =====
        Rectangle {
            anchors.fill: parent
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20 * win.uiScale
            spacing: 14 * win.uiScale

            // ===== header =====
            Item {
                width: parent.width
                height: 40 * win.uiScale

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("GAMING")
                    color: mt.nbInk
                    font.family: mt.fontDisplay
                    font.pixelSize: 24 * win.uiScale
                    font.letterSpacing: 6 * win.uiScale
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: SideMenuService.pinned === "gaming" ? "📌" : ""
                    color: mt.nbInkSub
                    font.pixelSize: 13 * win.uiScale
                }
            }

            // ===== Game Mode =====
            GamingTile {
                width: parent.width
                icon: "sports_esports"
                title: qsTr("Game Mode")
                sub: GameModeService.enabled
                    ? qsTr("Rendimiento arriba, avisos fuera")
                    : qsTr("Activa el modo rendimiento")
                on: GameModeService.enabled
                busy: GameModeService.busy
                onToggled: GameModeService.toggle()
            }

            // ===== Recorder =====
            Rectangle {
                width: parent.width
                height: 76 * win.uiScale
                radius: 12 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: ScreenRecorderService.recording ? mt.nbAccent : mt.nbBorder

                Row {
                    anchors.fill: parent
                    anchors.margins: 12 * win.uiScale
                    spacing: 12 * win.uiScale

                    Rectangle {
                        width: 52 * win.uiScale
                        height: 52 * win.uiScale
                        radius: 26 * win.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        color: ScreenRecorderService.recording ? mt.nbAccent : mt.nbSurface
                        border.width: 1
                        border.color: mt.nbBorder

                        SequentialAnimation on opacity {
                            running: ScreenRecorderService.recording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.45; duration: 700 }
                            NumberAnimation { to: 1; duration: 700 }
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            name: ScreenRecorderService.recording ? "stop" : "videocam"
                            size: 24 * win.uiScale
                            color: ScreenRecorderService.recording ? "#ffffff" : mt.nbInk
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScreenRecorderService.toggle()
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * win.uiScale
                        Text {
                            text: ScreenRecorderService.recording
                                ? win.fmt(ScreenRecorderService.duration)
                                : qsTr("Grabadora")
                            color: ScreenRecorderService.recording ? mt.nbAccent : mt.nbInk
                            font.family: mt.fontDisplay
                            font.pixelSize: ScreenRecorderService.recording
                                ? 26 * win.uiScale : 17 * win.uiScale
                        }
                        Text {
                            text: ScreenRecorderService.recording
                                ? qsTr("Grabando pantalla")
                                : qsTr("Toca para grabar · entra al juego")
                            color: mt.nbInkSub
                            font.pixelSize: 12 * win.uiScale
                        }
                    }
                }
            }

            // ===== Notifications =====
            GamingTile {
                width: parent.width
                icon: win.qsSource && win.qsSource.notificationsOn
                    ? "notifications_active" : "notifications_off"
                title: qsTr("Avisos")
                sub: win.qsSource && win.qsSource.notificationsOn
                    ? qsTr("Llegan normalmente")
                    : qsTr("Silenciados: no molestan")
                on: win.qsSource ? !win.qsSource.notificationsOn : false
                onToggled: if (win.qsSource) win.qsSource.toggleNotifications()
            }

            // ===== Keep Awake =====
            GamingTile {
                width: parent.width
                icon: "local_cafe"
                title: qsTr("Keep Awake")
                sub: win.qsSource && win.qsSource.keepAwakeOn
                    ? qsTr("La pantalla no se apaga")
                    : qsTr("Apagado de pantalla normal")
                on: win.qsSource ? win.qsSource.keepAwakeOn : false
                onToggled: if (win.qsSource) win.qsSource.toggleKeepAwake()
            }

            // ===== live stats =====
            Column {
                width: parent.width
                spacing: 8 * win.uiScale

                Text {
                    text: qsTr("SISTEMA")
                    color: mt.nbInkSub
                    font.family: mt.fontDisplay
                    font.pixelSize: 12 * win.uiScale
                    font.letterSpacing: 4 * win.uiScale
                }

                GamingMeter {
                    width: parent.width
                    label: qsTr("CPU")
                    value: stats.cpuPercent
                }

                GamingMeter {
                    width: parent.width
                    label: qsTr("RAM")
                    value: stats.memPercent
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: qsTr("Toca el borde derecho para abrir · Esc cierra")
                color: mt.nbInkSub
                font.pixelSize: 12 * win.uiScale
            }
        }
    }

    // CPU/RAM poller: only samples while the drawer is on screen.
    ResourceSource {
        id: stats
        wanted: win.slide > 0.5
    }

    function fmt(sec) {
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    component GamingTile: Rectangle {
        id: tile
        property string icon: ""
        property string title: ""
        property string sub: ""
        property bool on: false
        property bool busy: false
        signal toggled()

        height: 64 * win.uiScale
        radius: 12 * win.uiScale
        color: tile.on ? Qt.alpha(mt.nbAccent, 0.12) : mt.nbRaised
        border.width: 1
        border.color: tile.on ? mt.nbAccent : mt.nbBorder

        Row {
            anchors.fill: parent
            anchors.margins: 12 * win.uiScale
            spacing: 12 * win.uiScale

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: tile.icon
                size: 22 * win.uiScale
                color: tile.on ? mt.nbAccent : mt.nbInk
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 22 * win.uiScale - 12 * win.uiScale - 48 * win.uiScale
                spacing: 1
                Text {
                    text: tile.title
                    color: mt.nbInk
                    font.pixelSize: 15 * win.uiScale
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: tile.sub
                    color: mt.nbInkSub
                    font.pixelSize: 12 * win.uiScale
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 44 * win.uiScale
                height: 24 * win.uiScale
                radius: 12 * win.uiScale
                color: tile.on ? mt.nbAccent : mt.nbSurface
                border.width: 1
                border.color: tile.on ? mt.nbAccent : mt.nbBorder

                Rectangle {
                    x: tile.on ? parent.width - width - 2 * win.uiScale : 2 * win.uiScale
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18 * win.uiScale
                    height: 18 * win.uiScale
                    radius: 9 * win.uiScale
                    color: tile.on ? "#ffffff" : mt.nbInkSub
                    Behavior on x { NumberAnimation { duration: 140 } }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }
    }

    component GamingMeter: Column {
        id: meter
        property string label: ""
        property real value: 0

        spacing: 4 * win.uiScale

        Item {
            width: parent.width
            height: 16 * win.uiScale
            Text {
                anchors.left: parent.left
                text: meter.label
                color: mt.nbInk
                font.pixelSize: 13 * win.uiScale
            }
            Text {
                anchors.right: parent.right
                text: Math.round(meter.value) + "%"
                color: mt.nbInkSub
                font.family: mt.fontDisplay
                font.pixelSize: 13 * win.uiScale
            }
        }

        Rectangle {
            width: parent.width
            height: 6 * win.uiScale
            radius: 3 * win.uiScale
            color: mt.nbBorder

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, meter.value / 100))
                height: parent.height
                radius: 3 * win.uiScale
                color: meter.value > 85 ? mt.nbAccent : mt.nbInkSub
                Behavior on width { NumberAnimation { duration: 250 } }
            }
        }
    }
}