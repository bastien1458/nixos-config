import QtQuick
import Quickshell
import Quickshell.Wayland

Overlay {
  id: window

  screen: Hud.screenNamed(Hud.osOutput)
  open: Hud.osOpen
  WlrLayershell.namespace: "cyberdeck-os"
  blurItem: backdrop
  onDismissed: Hud.osOpen = false

  Item {
    id: panel
    anchors.right: parent.right
    anchors.rightMargin: 150
    y: Settings.barBottom ? parent.height - height - 6 + (1 - window.reveal) * 16 : 6 - (1 - window.reveal) * 16
    width: 620
    height: content.implicitHeight
    opacity: Math.min(1, window.reveal * 2)

    Backdrop { id: backdrop }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    OsContent {
      id: content
      width: parent.width
      reveal: window.reveal
    }
  }
}
