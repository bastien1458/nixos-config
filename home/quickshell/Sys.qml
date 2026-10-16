pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and uptime, sampled only while something is looking at them.
Singleton {
  id: sys

  property bool active: Hud.ccOpen
  property real cpu: 0
  property real memUsed: 0
  property real memTotal: 1
  property string uptime: ""
  property string kernel: ""
  property var last: null

  readonly property real mem: memUsed / memTotal

  function parse(text) {
    const cpuLine = /^cpu\s+(.*)$/m.exec(text)
    if (cpuLine) {
      const v = cpuLine[1].trim().split(/\s+/).map(Number)
      const idle = v[3] + (v[4] || 0)
      const total = v.reduce((a, b) => a + b, 0)
      if (last) {
        const dt = total - last.total
        cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - (idle - last.idle) / dt)) : cpu
      }
      last = { idle: idle, total: total }
    }
    const total = /MemTotal:\s+(\d+)/.exec(text)
    const avail = /MemAvailable:\s+(\d+)/.exec(text)
    if (total && avail) {
      memTotal = parseInt(total[1]) / 1048576
      memUsed = memTotal - parseInt(avail[1]) / 1048576
    }
    const up = /^UPTIME (\d+)/m.exec(text)
    if (up) {
      const s = parseInt(up[1])
      const d = Math.floor(s / 86400)
      const h = Math.floor(s % 86400 / 3600)
      const m = Math.floor(s % 3600 / 60)
      uptime = (d > 0 ? d + "D " : "") + String(h).padStart(2, "0") + "H " + String(m).padStart(2, "0") + "M"
    }
    const kern = /^KERNEL (\S+)/m.exec(text)
    if (kern) kernel = kern[1]
  }

  Process {
    id: probe
    command: ["sh", "-c", "head -1 /proc/stat; head -3 /proc/meminfo; echo UPTIME $(cut -d. -f1 /proc/uptime); echo KERNEL $(uname -r)"]
    stdout: StdioCollector {
      onStreamFinished: sys.parse(this.text)
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: sys.active
    triggeredOnStart: true
    onTriggered: probe.running = true
  }
}
