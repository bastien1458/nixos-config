pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager state. Refreshed when `nmcli monitor` reports a change,
// plus a slow safety poll for the wifi signal strength.
Singleton {
  id: net

  property string kind: "offline"
  property string name: ""
  property int strength: 0
  readonly property string icon: kind === "ethernet" ? "lan" : (kind === "wifi" ? "wifi" : "offline")
  readonly property string label: kind === "ethernet" ? "LAN" : (kind === "wifi" ? strength + "%" : "OFFLINE")

  function parse(text) {
    let found = "offline"
    let conn = ""
    for (const line of text.split("\n")) {
      const parts = line.split(":")
      if (parts.length < 3 || parts[1] !== "connected") continue
      if (parts[0] === "ethernet") { found = "ethernet"; conn = parts.slice(2).join(":"); break }
      if (parts[0] === "wifi" && found === "offline") { found = "wifi"; conn = parts.slice(2).join(":") }
    }
    kind = found
    name = conn
    if (found === "wifi") wifiSignal.running = true
  }

  Process {
    id: devices
    command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: net.parse(this.text)
    }
  }

  Process {
    id: wifiSignal
    command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL", "device", "wifi"]
    stdout: StdioCollector {
      onStreamFinished: {
        const line = this.text.split("\n").find(l => l.startsWith("yes:"))
        if (line) net.strength = parseInt(line.split(":")[1]) || 0
      }
    }
  }

  Process {
    id: monitor
    command: ["nmcli", "monitor"]
    running: true
    stdout: SplitParser {
      onRead: debounce.restart()
    }
    onExited: monitorRestart.start()
  }

  Timer {
    id: monitorRestart
    interval: 10000
    onTriggered: monitor.running = true
  }

  Timer {
    id: debounce
    interval: 400
    onTriggered: devices.running = true
  }

  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: devices.running = true
  }
}
