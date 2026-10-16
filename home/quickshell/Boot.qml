import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// First login after a boot: the deck powers on over the desktop, then the
// shutters open on it. Restarting the shell (Super+Shift+R) does not replay it.
Scope {
  id: boot

  property bool active: false
  property real open: 0

  readonly property string user: (Quickshell.env("USER") || "netrunner").toUpperCase()
  readonly property var lines: [
    ["NEURAL LINK ................................ ESTABLISHED", "ok"],
    ["NETRUNNER ID // " + user, "info"],
    ["FLASHING " + (Theme.osInfo.name || "CYBERDECK") + " ...... OK", "ok"],
    ["KIROSHI OPTICS // " + Quickshell.screens.length + " OUTPUT" + (Quickshell.screens.length > 1 ? "S" : "") + " ............ CALIBRATED", "ok"],
    ["DAEMONS // BAR, HUD, QUICKHACKS, BREACH ........ ONLINE", "ok"],
    ["ICE ...................................... ACTIVE", "ok"],
    ["WARNING: BLACKWALL INTEGRITY " + Blackwall.integrity.toFixed(2) + "%", "warn"],
    ["> WELCOME TO NIGHT CITY", "info"]
  ]

  signal begun()

  function begin() {
    active = true
    open = 0
    Sounds.play("boot")
    begun()
  }

  function reveal() {
    if (!shutters.running && open === 0) shutters.start()
  }

  // the runtime dir lives as long as the login: a marker there means this
  // login already went through the boot
  Process {
    running: true
    command: ["sh", "-c", "m=\"${XDG_RUNTIME_DIR:-/tmp}/cyberdeck-online\"; if [ -e \"$m\" ]; then echo seen; else : > \"$m\"; echo first; fi"]
    stdout: StdioCollector {
      onStreamFinished: if (this.text.trim() === "first") boot.begin()
    }
  }

  SequentialAnimation {
    id: shutters
    NumberAnimation { target: boot; property: "open"; to: 1; duration: 750; easing.type: Easing.InOutCubic }
    ScriptAction { script: boot.active = false }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData

      screen: modelData
      visible: boot.active
      color: "transparent"
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      // purely visual: clicks and keys go to the desktop underneath
      mask: Region {}
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "cyberdeck-boot"

      Connections {
        target: boot
        function onBegun() { power.start() }
      }

      // the shutters
      Rectangle {
        width: parent.width
        height: Math.ceil(parent.height / 2)
        y: -height * boot.open
        color: Theme.mix(Theme.bg, Qt.rgba(0, 0, 0, 1), 0.55)
      }

      Rectangle {
        width: parent.width
        height: Math.ceil(parent.height / 2)
        y: parent.height / 2 + height * boot.open
        color: Theme.mix(Theme.bg, Qt.rgba(0, 0, 0, 1), 0.55)
      }

      PowerOn {
        id: power
        anchors.fill: parent
        opacity: Math.max(0, 1 - boot.open * 2.5)
        lines: boot.lines
        subtitle: "WELCOME BACK, " + boot.user
        onFinished: boot.reveal()
      }

      // the seam between the shutters, glowing while they part
      Rectangle {
        width: parent.width
        height: 2
        y: parent.height / 2 - 1
        color: Theme.primary
        opacity: boot.open > 0 && boot.open < 0.4 ? 1 - boot.open * 2.5 : 0
      }
    }
  }
}
