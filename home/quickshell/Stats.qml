pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Eurodollars and breach records, shared with cyberdeck-theme (Blackwall unlock).
Singleton {
  id: stats

  property int eddies: 0
  property int breaches: 0
  property int perfect: 0
  property bool blackwall: false
  // ICEPICK daemon: cheaper quickhacks for an hour
  property real icepickUntil: 0
  property real now: Date.now()
  readonly property bool icepick: icepickUntil > now

  readonly property string path: Theme.stateDir + "/stats.json"

  function record(earned, wasPerfect, wall, daemons) {
    eddies += earned
    breaches += 1
    if (wasPerfect) perfect += 1
    if (wall) blackwall = true
    if (daemons && daemons.indexOf("ICEPICK") >= 0) {
      now = Date.now()
      icepickUntil = now + 3600 * 1000
    }
    save()
  }

  function save() {
    file.setText(JSON.stringify({ eddies: eddies, breaches: breaches, perfect: perfect, blackwall: blackwall, icepickUntil: icepickUntil }, null, 1) + "\n")
  }

  Timer {
    interval: 60 * 1000
    repeat: true
    running: stats.icepickUntil > stats.now
    onTriggered: stats.now = Date.now()
  }

  function format(value) {
    return Number(value).toLocaleString(Qt.locale("en_US"), "f", 0)
  }

  FileView {
    id: file
    path: stats.path
    onLoaded: {
      try {
        const data = JSON.parse(text())
        stats.eddies = data.eddies || 0
        stats.breaches = data.breaches || 0
        stats.perfect = data.perfect || 0
        stats.blackwall = data.blackwall === true
        stats.icepickUntil = data.icepickUntil || 0
        stats.now = Date.now()
      } catch (error) {
        console.warn("cyberdeck: unreadable stats: " + error)
      }
    }
  }
}
