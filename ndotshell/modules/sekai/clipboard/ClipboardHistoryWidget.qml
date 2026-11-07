import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Clipboard History Widget: shows recent clipboard items, click to copy, pin, delete
Item {
    id: root
    property int maxVisible: 8
    property real itemHeight: 56
    implicitWidth: 320
    implicitHeight: Math.min(root.maxVisible, ClipboardHistoryService.history.length) * root.itemHeight + 8

    // Search filter
    property string filter: ""

    readonly property var filteredHistory: {
        if (root.filter === "") return ClipboardHistoryService.history
        return ClipboardHistoryService.history.filter(function(item) {
            return item.type === "text" && item.content.toLowerCase().includes(root.filter.toLowerCase())
        })
    }

    Column {
        id: list
        spacing: 4
        anchors.fill: parent

        // Search bar
        Item {
            width: parent.width
            height: 40
            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: 8
                color: mt.pSurface
                border.width: 1
                border.color: mt.pLine
                TextField {
                    id: searchField
                    anchors.fill: parent
                    anchors.margins: 12
                    placeholderText: qsTr("Buscar en historial...")
                    font.family: mt.fontFamily
                    font.pixelSize: 14
                    color: mt.pInk
                    background: Rectangle { color: "transparent" }
                    onTextChanged: root.filter = text
                }
                MaterialIcon {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 12
                    name: "search"
                    size: 20
                    color: mt.pInkSub
                }
            }
        }

        // List
        Flickable {
            id: flick
            width: parent.width
            height: parent.height - 40
            clip: true
            contentHeight: list.implicitHeight - 40
            ScrollBar.vertical: ScrollBar { width: 4; policy: ScrollBar.AsNeeded }

            Column {
                id: innerList
                spacing: 4
                width: flick.width
                Repeater {
                    model: root.filteredHistory
                    delegate: ClipboardItem {
                        width: parent.width
                        itemData: modelData
                        onCopyRequested: {
                            ClipboardHistoryService.copyToClipboard(modelData.id)
                            // Visual feedback
                            tooltip.text = qsTr("Copiado")
                            tooltip.open()
                        }
                        onPinRequested: ClipboardHistoryService.pin(modelData.id)
                        onDeleteRequested: ClipboardHistoryService.remove(modelData.id)
                    }
                }
            }
        }

        // Empty state
        Item {
            width: parent.width
            height: flick.height
            visible: root.filteredHistory.length === 0
            Text {
                anchors.centerIn: parent
                text: root.filter ? qsTr("Sin coincidencias") : qsTr("Historial vacío")
                color: mt.pInkSub
                font.family: mt.fontFamily
                font.pixelSize: 14
            }
        }
    }

    ToolTip {
        id: tooltip
        text: ""
        timeout: 800
    }
}

// Individual item
Component {
    id: ClipboardItem
    Item {
        id: item
        required property var itemData
        height: 56
        width: parent.width

        signal copyRequested()
        signal pinRequested()
        signal deleteRequested()

        Rectangle {
            id: bg
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: mt.pSurface
            border.width: itemData.pinned ? 1 : 0
            border.color: itemData.pinned ? mt.accentCyan : "transparent"

            Row {
                anchors.fill: parent
                spacing: 12

                // Icon
                Rectangle {
                    width: 40
                    height: 40
                    radius: 8
                    color: itemData.type === "image" ? mt.pSurfaceHover : mt.accentCyan
                    MaterialIcon {
                        anchors.centerIn: parent
                        name: itemData.type === "image" ? "image" : "content_copy"
                        size: 20
                        color: itemData.type === "image" ? mt.pInk : mt.pSurface
                    }
                }

                // Content
                Column {
                    spacing: 2
                    width: parent.width - 40 - 12 - 80
                    Text {
                        width: parent.width
                        text: itemData.type === "image"
                            ? qsTr("[Imagen] %1×%2").arg(itemData.content.width || "?").arg(itemData.content.height || "?")
                            : itemData.content
                        color: mt.pInk
                        font.family: mt.fontFamily
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        text: Qt.formatDateTime(itemData.timestamp, "HH:mm  dd/MM")
                        color: mt.pInkSub
                        font.family: mt.fontFamily
                        font.pixelSize: 11
                    }
                }

                // Actions
                Row {
                    spacing: 4
                    // Pin
                    IconButton {
                        icon: itemData.pinned ? "push_pin" : "push_pin_outlined"
                        color: itemData.pinned ? mt.accentCyan : mt.pInkSub
                        onClicked: pinRequested()
                        toolTip: qsTr(itemData.pinned ? "Desanclar" : "Anclar")
                    }
                    // Copy
                    IconButton {
                        icon: "content_copy"
                        onClicked: copyRequested()
                        toolTip: qsTr("Copiar")
                    }
                    // Delete
                    IconButton {
                        icon: "delete_outline"
                        color: mt.pInkSub
                        onClicked: deleteRequested()
                        toolTip: qsTr("Eliminar")
                        visible: !itemData.pinned
                    }
                }
            }
        }
    }
}

// Simple icon button
Component {
    id: IconButton
    MouseArea {
        id: ma
        required property string icon
        property color color: mt.pInkSub
        property string toolTip: ""
        width: 36
        height: 36
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Rectangle {
            anchors.centerIn: parent
            width: 32
            height: 32
            radius: 8
            color: ma.pressed ? mt.pSurfaceHover : (ma.containsMouse ? mt.pLine : "transparent")
            border.width: 1
            border.color: "transparent"
            MaterialIcon {
                anchors.centerIn: parent
                name: icon
                size: 18
                color: color
            }
        }
        onClicked: { if (onClicked) onClicked() }
    }
}