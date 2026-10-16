import QtQuick
import Quickshell
import Quickshell.Wayland

// One bar per output.
PanelWindow {
  id: window

  required property var modelData

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: 40
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
