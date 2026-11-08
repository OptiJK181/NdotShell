import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.sekai.ai

// AI drawer — full height en el lado derecho (patrón Bar/Gaming), card con
// las esquinas redondeadas. Entra desde el borde con el mismo rebote
// gelatinoso que el resto de paneles (OutElastic), y el input sale solo en
// el card (mask).
//
// Se abre con AiService.drawerOpen: la tecla de barra, el orbe del
// escritorio y `qs -c ndotshell ipc call ai open` empujan lo mismo.
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

    readonly property real cardW: 440
    readonly property real topPad: SettingsService.flag("bar.visible")
        ? BarPositionService.thicknessFor("top") + 8 : 14
    readonly property real bottomPad: 14

    property real slide: AiService.drawerOpen ? 1 : 0
    Behavior on slide {
        NumberAnimation {
            duration: 620
            easing.type: Easing.OutElastic
            easing.amplitude: 1.2
            easing.period: 0.45
        }
    }

    visible: win.slide > 0.001
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: AiService.drawerOpen
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // only the card takes input
    mask: Region { item: card }

    Item {
        id: card

        x: Math.round(parent.width - parent.width * win.slide)
        y: Math.round(win.topPad)
        width: Math.round(parent.width)
        height: Math.round(parent.height - win.topPad - win.bottomPad)

        focus: AiService.drawerOpen
        Keys.onEscapePressed: {
            if (AiService.busy) AiService.stop()
            else AiService.drawerOpen = false
        }

        AiChatPanel {
            anchors.fill: parent
            active: AiService.drawerOpen
            showClose: true
            onCloseRequested: AiService.drawerOpen = false
        }
    }
}
