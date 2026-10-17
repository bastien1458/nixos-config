import QtQuick
import Quickshell
import Quickshell.Wayland

// Wallpaper selector: every image of home/assets/wallpapers, recoloured
// through the active OS. Opened from the bar, the quickhack menu or Super+W.
Overlay {
  id: window

  screen: Hud.screenNamed(Hud.wallOutput)
  open: Hud.wallOpen
  WlrLayershell.namespace: "cyberdeck-wallpaper"
  blurItem: panel
  blurPad: backdrop.pad
  onDismissed: Hud.wallOpen = false

  Item {
    id: panel
    anchors.horizontalCenter: parent.horizontalCenter
    y: Settings.barBottom ? parent.height - height - 6 + (1 - window.reveal) * 16 : 6 - (1 - window.reveal) * 16
    width: Math.min(parent.width - 48, 1140)
    height: content.implicitHeight
    opacity: Math.min(1, window.reveal * 2)

    Backdrop { id: backdrop }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    WallContent {
      id: content
      width: parent.width
      reveal: window.reveal
      maxHeight: window.height - 40
      focus: true
      onCloseRequested: Hud.wallOpen = false
    }
  }
}
