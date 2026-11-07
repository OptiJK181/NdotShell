import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The TAREAS tab of Edit Desktop's shelf (EditTray.qml): the task bars that
// are not the bar itself — the two side drawers, their edge hotspots and the
// Dynamic Island. The same little keys as the DOCK tab (EditDockBoard.qml):
// no card or lane, loose keys with open space.
//
//   GAMING    right-edge drawer, Nothing gaming      SettingsService "side.gaming"
//   FOCUS     left-edge drawer, ofimática            SettingsService "side.work"
//   HOTSPOTS  double-tap the corner opens            SettingsService "side.hotspots"
//   ISLAND    the Dynamic Island pill                SettingsService "side.island"
//
// Same switches as Settings → Desktop → Barras de tareas, so the two agree.
Item {
    id: root

    property string hover: ""

    function labelFor(key, on) {
        return key + (on ? " · on" : " · off")
    }

    readonly property var entries: [
        { id: "side.gaming", key: "GAMING", icon: "sports_esports" },
        { id: "side.work", key: "FOCUS", icon: "center_focus_strong" },
        { id: "side.hotspots", key: "HOTSPOTS", icon: "crop" },
        { id: "side.island", key: "ISLAND", icon: "moon-stars" }
    ]

    readonly property int onCount: entries.filter(e => SettingsService.flag(e.id)).length

    Column {
        spacing: 9

        EditPickHead {
            title: "BARRAS DE TAREAS"
            value: root.hover !== ""
                ? root.labelFor(root.hover,
                    SettingsService.flag(root.entries.find(e => e.key === root.hover)?.id ?? ""))
                : root.onCount + " of " + root.entries.length + " on"
        }

        Row {
            spacing: 8

            Repeater {
                model: root.entries

                EditPickKey {
                    required property var modelData

                    icon: modelData.icon
                    on: SettingsService.flag(modelData.id)
                    onPicked: SettingsService.toggle(modelData.id)
                    onHoveredChanged: {
                        if (hovered)
                            root.hover = modelData.key
                        else if (root.hover === modelData.key)
                            root.hover = ""
                    }
                }
            }
        }
    }

    Column {
        spacing: 9
        anchors.top: parent.top
        anchors.topMargin: 120
        visible: false
    }
}