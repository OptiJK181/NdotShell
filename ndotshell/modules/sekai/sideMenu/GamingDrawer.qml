import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.sideMenu

// Gaming drawer — ancla top+bottom+right (full height, como la Bar).
// El card vive adentro con topPadding para la barra. Doble toque en la
// esquina superior derecha lo abre. Gelatinoso, Caelestia-style.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    property var qsSource
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    // ===== full height en el lado derecho (patrón Bar.qml) =====
    anchors { top: true; bottom: true; right: true }
    implicitWidth: Math.round(cardW * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 330
    // espacio para la barra arriba
    readonly property real topPad: SettingsService.flag("bar.visible")
        ? BarPositionService.thicknessFor("top") + 6 : 12

    property real slide: SideMenuService.open === "gaming"
        && SettingsService.flag("side.gaming") ? 1 : 0
    Behavior on slide {
        NumberAnimation {
            duration: 640
            easing.type: Easing.OutElastic
            easing.amplitude: 1.3
            easing.period: 0.45
        }
    }

    visible: win.slide > 0.001
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.open === "gaming"
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // input solo en el card (el resto del window es transparente)
    mask: Region { item: card }

    // ===== driver de stagger =====
    Item {
        id: driver
        property real t: SideMenuService.open === "gaming" ? 1 : 0
        Behavior on t { NumberAnimation { duration: 640; easing.type: Easing.OutCubic } }
        function prog(i) {
            return Math.max(0, Math.min(1, (t - (0.06 + i * 0.07)) / 0.35))
        }
    }

    // ===== el card: x = window.width - cardW (pegado al borde derecho) =====
    Item {
        id: card

        x: Math.round(parent.width - parent.width * slide)
        y: Math.round(win.topPad)
        width: Math.round(parent.width)
        height: Math.round(parent.height - win.topPad)

        HoverHandler { id: cardHover }

        focus: SideMenuService.open === "gaming"
        Keys.onEscapePressed: SideMenuService.hide()

        // slab
        Rectangle {
            anchors.fill: parent
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder
        }

        // accent hairline en el borde de pantalla
        Rectangle {
            anchors.right: parent.right
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
            anchors.topMargin: 20 * win.uiScale
            anchors.bottomMargin: 14 * win.uiScale
            spacing: 8 * win.uiScale

            // ===== header =====
            Item {
                width: parent.width
                height: 44 * win.uiScale

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: qsTr("GAMING")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 26 * win.uiScale
                        font.letterSpacing: 7 * win.uiScale
                    }

                    Text {
                        text: qsTr("MODO RENDIMIENTO")
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 9 * win.uiScale
                        font.letterSpacing: 3 * win.uiScale
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: SideMenuService.pinned === "gaming"
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

            // ===== menu =====
            DrawerMenuItem {
                appear: driver.prog(0)
                fromRight: true
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("GAME MODE")
                selected: GameModeService.enabled
                onActivated: GameModeService.toggle()
            }

            DrawerMenuItem {
                appear: driver.prog(1)
                fromRight: true
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: ScreenRecorderService.recording
                    ? qsTr("GRABANDO %1").arg(win.fmt(ScreenRecorderService.duration))
                    : qsTr("GRABAR PANTALLA")
                selected: ScreenRecorderService.recording
                onActivated: ScreenRecorderService.toggle()
            }

            DrawerMenuItem {
                appear: driver.prog(2)
                fromRight: true
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                action: true
                text: qsTr("GRABAR VENTANA")
                onActivated: ScreenRecorderService.startWindow()
            }

            DrawerMenuItem {
                appear: driver.prog(3)
                fromRight: true
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                action: true
                text: qsTr("GRABAR REGIÓN")
                onActivated: ScreenRecorderService.startRegion()
            }

            DrawerMenuItem {
                appear: driver.prog(4)
                fromRight: true
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                action: true
                text: qsTr("CAPTURA")
                onActivated: {
                    SideMenuService.hide()
                    RegionService.showLater("copy")
                }
            }

            DrawerMenuItem {
                appear: driver.prog(5)
                fromRight: true
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("AVISOS")
                selected: win.qsSource ? !win.qsSource.notificationsOn : false
                onActivated: if (win.qsSource) win.qsSource.toggleNotifications()
            }

            DrawerMenuItem {
                appear: driver.prog(6)
                fromRight: true
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("KEEP AWAKE")
                selected: win.qsSource ? win.qsSource.keepAwakeOn : false
                onActivated: if (win.qsSource) win.qsSource.toggleKeepAwake()
            }

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // ===== sistema + ventilador =====
            Column {
                width: parent.width
                spacing: 8 * win.uiScale

                Text {
                    text: qsTr("SISTEMA")
                    color: mt.nbInkSub
                    font.family: mt.fontDisplay
                    font.pixelSize: 11 * win.uiScale
                    font.letterSpacing: 4 * win.uiScale
                }

                Row {
                    width: parent.width
                    spacing: 12 * win.uiScale

                    GamingFan {
                        width: 60 * win.uiScale
                        height: 60 * win.uiScale
                        cpu: stats.cpuPercent
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 60 * win.uiScale - 12 * win.uiScale
                        spacing: 9 * win.uiScale

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
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: qsTr("Doble toque en la esquina · Esc cierra")
                color: mt.nbInkSub
                font.pixelSize: 11 * win.uiScale
            }
        }
    }

    ResourceSource {
        id: stats
        wanted: win.slide > 0.5
    }

    function fmt(sec) {
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    component GamingFan: Rectangle {
        id: fan
        property real cpu: 0
        property real angle: 0

        radius: width / 2
        color: mt.nbRaised
        border.width: 1
        border.color: mt.nbBorder

        Timer {
            interval: Math.max(16, 58 - fan.cpu * 0.42)
            running: fan.visible
            repeat: true
            onTriggered: fan.angle = (fan.angle + 7) % 360
        }

        Item {
            anchors.centerIn: parent
            width: parent.width - 10 * win.uiScale
            height: parent.height - 10 * win.uiScale
            rotation: fan.angle

            Repeater {
                model: 3

                Rectangle {
                    required property int index
                    width: 16 * win.uiScale
                    height: parent.height / 2 - 3 * win.uiScale
                    radius: width / 2
                    color: fan.cpu > 85 ? mt.nbAccent : mt.nbInkSub
                    opacity: 0.9
                    x: (parent.width - width) / 2
                    y: 3 * win.uiScale
                    transform: Rotation {
                        origin.x: width / 2
                        origin.y: height
                        angle: index * 120
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 13 * win.uiScale
                height: 13 * win.uiScale
                radius: 7 * win.uiScale
                color: mt.nbSurface
                border.width: 1
                border.color: mt.nbBorder
            }
        }

        Text {
            anchors.top: parent.bottom
            anchors.topMargin: 4 * win.uiScale
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(600 + fan.cpu * 42) + ""
            color: mt.nbInkSub
            font.family: mt.fontDisplay
            font.pixelSize: 10 * win.uiScale
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