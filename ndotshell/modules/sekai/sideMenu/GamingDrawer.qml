import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.sideMenu

// Gaming drawer — Caelestia hotspot on the right edge; Sekai power-menu
// typography inside (skewed wedge + italic accent word on select).
// 100% gaming: Game Mode, recorder (screen / window / region), screenshot,
// notifications, Keep Awake, CPU/RAM meters.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    property var qsSource
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; right: true }
    implicitWidth: Math.round(cardW * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 330

    property real slide: SideMenuService.open === "gaming"
        && SettingsService.flag("side.gaming") ? 1 : 0
    Behavior on slide { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    visible: win.slide > 0.001
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.open === "gaming"
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    Item {
        id: card

        x: Math.round(win.width - win.cardW * win.uiScale * win.slide)
        y: 0
        width: Math.round(win.cardW * win.uiScale)
        height: win.height

        HoverHandler { id: cardHover }
        Binding { target: SideMenuService; property: "cardHovered"; value: cardHover.hovered }

        focus: SideMenuService.open === "gaming"
        Keys.onEscapePressed: SideMenuService.hide()

        // slab
        Rectangle {
            anchors.fill: parent
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

            // ===== the menu =====
            DrawerMenuItem {
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

            // ===== live stats =====
            Column {
                width: parent.width
                spacing: 9 * win.uiScale

                Text {
                    text: qsTr("SISTEMA")
                    color: mt.nbInkSub
                    font.family: mt.fontDisplay
                    font.pixelSize: 11 * win.uiScale
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