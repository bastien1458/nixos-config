import QtQuick
import Quickshell
import Quickshell.Wayland

// One bar per output, at the top or the bottom (see Settings).
PanelWindow {
  id: window

  required property var modelData

  screen: modelData
  anchors {
    top: !Settings.barBottom
    bottom: Settings.barBottom
    left: true
    right: true
  }
  implicitHeight: Settings.barHeight
  color: "transparent"
  WlrLayershell.namespace: "cyberdeck-bar"
  WlrLayershell.layer: WlrLayer.Top

  BarContent {
    anchors.fill: parent
    output: window.modelData.name
    window: window
    onTrayMenuRequested: (item, x) => trayMenu.show(item, x)
  }

  TrayMenu {
    id: trayMenu
    screen: window.modelData
  }
}
