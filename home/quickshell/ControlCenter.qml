import QtQuick
import Quickshell
import Quickshell.Wayland

Overlay {
  id: window

  screen: Hud.screenNamed(Hud.ccOutput)
  open: Hud.ccOpen
  WlrLayershell.namespace: "cyberdeck-cc"
  blurItem: panel
  blurPad: backdrop.pad
  onDismissed: Hud.ccOpen = false

  Item {
    id: panel
    anchors.right: parent.right
    anchors.rightMargin: 12
    y: Settings.barBottom ? parent.height - height - 6 + (1 - window.reveal) * 16 : 6 - (1 - window.reveal) * 16
    width: 470
    height: Math.min(content.implicitHeight, parent.height - 16)
    opacity: Math.min(1, window.reveal * 2)

    // swallow clicks so the background does not close the panel
    Backdrop { id: backdrop }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Flickable {
      anchors.fill: parent
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height

      CcContent {
        id: content
        width: panel.width
        reveal: window.reveal
      }
    }

    // scan line sweeping down while the panel opens
    Rectangle {
      width: parent.width
      height: 2
      y: parent.height * window.reveal
      color: Theme.primary
      opacity: window.reveal < 1 ? 0.8 : 0
    }
  }
}
