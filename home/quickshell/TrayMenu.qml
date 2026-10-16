import QtQuick
import Quickshell
import Quickshell.Wayland

// Tray menus drawn by the shell instead of the toolkit, with submenu drilling.
Overlay {
  id: window

  property var item: null
  property real atX: 0
  property var stack: []

  readonly property var handle: stack.length > 0 ? stack[stack.length - 1] : (item ? item.menu : null)

  WlrLayershell.namespace: "cyberdeck-tray"
  openDuration: 160
  closeDuration: 120
  onDismissed: open = false

  function show(trayItem, x) {
    item = trayItem
    atX = x
    stack = []
    open = true
  }

  QsMenuOpener {
    id: opener
    menu: window.handle
  }

  Item {
    id: panel
    x: Math.max(8, Math.min(window.width - width - 8, window.atX - width / 2 + 12))
    y: 2
    width: 280
    height: entries.height + 34
    opacity: window.reveal
    transform: Translate { y: (1 - window.reveal) * -10 }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Plate {
      anchors.fill: parent
      cut: 12
      cutBL: 6
      fill: Theme.alpha(Theme.bg, 0.96)
      stroke: Theme.primary
    }

    Text {
      x: 12
      y: 8
      width: parent.width - 24
      text: (window.item ? (window.item.tooltipTitle || window.item.title || window.item.id || "TRAY") : "").toUpperCase()
      color: Theme.primary
      elide: Text.ElideRight
      font.family: Theme.fontUi
      font.pixelSize: 13
      font.weight: Font.Bold
      font.letterSpacing: 1.5
    }

    Column {
      id: entries
      x: 4
      y: 28
      width: parent.width - 8

      Item {
        visible: window.stack.length > 0
        width: parent.width
        height: 26

        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.primary, backArea.containsMouse ? 0.15 : 0) }

        Row {
          x: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6
          Icon { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; name: "left"; color: Theme.primary }
          Text { text: "BACK"; color: Theme.primary; font.family: Theme.fontUi; font.pixelSize: 14; font.weight: Font.Bold }
        }

        Clickable {
          id: backArea
          anchors.fill: parent
          cursorShape: Qt.ArrowCursor
          onClicked: window.stack = window.stack.slice(0, -1)
        }
      }

      Repeater {
        model: opener.children ? opener.children.values : []
        delegate: Item {
          id: entry
          required property var modelData
          width: entries.width
          height: modelData.isSeparator ? 9 : 26

          Rectangle {
            visible: entry.modelData.isSeparator
            anchors.centerIn: parent
            width: parent.width - 16
            height: 1
            color: Theme.frameDim
          }

          Rectangle {
            visible: !entry.modelData.isSeparator
            anchors.fill: parent
            color: Theme.alpha(Theme.primary, entryArea.containsMouse && entry.modelData.enabled ? 0.15 : 0)
          }

          Rectangle {
            visible: !entry.modelData.isSeparator && entry.modelData.buttonType !== 0
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            color: entry.modelData.checkState === Qt.Checked ? Theme.primary : "transparent"
            border.color: Theme.primary
            border.width: 1
          }

          Text {
            visible: !entry.modelData.isSeparator
            x: entry.modelData.buttonType !== 0 ? 26 : 10
            width: parent.width - x - 24
            anchors.verticalCenter: parent.verticalCenter
            text: (entry.modelData.text || "").replace(/_/g, "")
            color: entry.modelData.enabled ? Theme.fg : Theme.muted
            elide: Text.ElideRight
            font.family: Theme.fontUi
            font.pixelSize: 14
            font.weight: Font.DemiBold
          }

          Icon {
            visible: entry.modelData.hasChildren === true
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            name: "right"
            color: Theme.subtle
          }

          Clickable {
            id: entryArea
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            enabled: !entry.modelData.isSeparator && entry.modelData.enabled
            onClicked: {
              if (entry.modelData.hasChildren) {
                window.stack = window.stack.concat([entry.modelData])
              } else {
                entry.modelData.triggered()
                window.open = false
              }
            }
          }
        }
      }
    }
  }
}
