pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The soundscape of the deck: UI blips, the city ambience and the breach OST,
// all played through pw-play. Each sound is assets/sounds/<name>.mp3: drop a
// real file with the same name over a placeholder to change it.
Singleton {
  id: sounds

  // kept in $XDG_STATE_HOME/cyberdeck/sound.json, toggled from the control center
  property bool fx: true
  property bool ambience: true
  property real volume: 0.7

  readonly property string dir: decodeURIComponent(Qt.resolvedUrl("assets/sounds").toString().replace(/^file:\/\//, ""))
  readonly property string path: Theme.stateDir + "/sound.json"

  // loudness of each sound before the master volume
  readonly property var levels: ({
    hover: 0.22,
    click: 0.5,
    "matrix-hover": 0.3,
    "breach-success": 0.8,
    "breach-fail": 0.8,
    notification: 0.6,
    "deck-switch": 0.8,
    boot: 0.9,
    ambient: 0.25,
    breach: 0.45
  })

  // what should be looping right now
  readonly property string loop: Lock.locked ? "" : Hud.breachOpen ? "breach" : ambience ? "ambient" : ""
  property var lastPlayed: ({})

  function file(name) {
    return dir + "/" + name + ".mp3"
  }

  function level(name) {
    return (volume * (levels[name] !== undefined ? levels[name] : 0.5)).toFixed(2)
  }

  function play(name) {
    if (!fx || volume <= 0) return
    // sweeping the pointer over a list must not turn into a machine gun
    const now = Date.now()
    if (now - (lastPlayed[name] || 0) < 45) return
    lastPlayed[name] = now
    Quickshell.execDetached([Theme.bin("pwplay"), "--volume=" + level(name), file(name)])
  }

  // ALL -> FX ONLY -> MUTED -> ALL
  function cycle() {
    if (fx && ambience) ambience = false
    else if (fx) fx = false
    else {
      fx = true
      ambience = true
    }
    save()
  }

  function save() {
    store.setText(JSON.stringify({ fx: fx, ambience: ambience, volume: volume }, null, 1) + "\n")
  }

  function sync() {
    if (looper.running) {
      // a different track (or silence) is wanted: stop, restartTimer comes back here
      if (looper.track !== loop) {
        looper.stopping = true
        looper.running = false
      }
      return
    }
    if (loop === "") return
    looper.track = loop
    looper.running = true
  }

  onLoopChanged: sync()
  Component.onCompleted: sync()

  Process {
    id: looper
    property string track: ""
    property real startedAt: 0
    property bool stopping: false
    command: [Theme.bin("pwplay"), "--volume=" + sounds.level(track), sounds.file(track)]
    onStarted: startedAt = Date.now()
    // the track ended (or was stopped): loop it, backing off if pw-play keeps failing
    onRunningChanged: {
      if (running) return
      restartTimer.interval = !stopping && Date.now() - startedAt < 1500 ? 5000 : 40
      startedAt = 0
      stopping = false
      restartTimer.restart()
    }
  }

  Timer {
    id: restartTimer
    onTriggered: sounds.sync()
  }

  // the deck changing firmware
  Connections {
    target: Theme
    function onSwitchingChanged() {
      if (Theme.switching && Theme.pendingKind === "os") sounds.play("deck-switch")
    }
  }

  Connections {
    target: Notifs
    function onArrived(n) {
      if (!Hud.dnd || Notifs.isCritical(n)) sounds.play("notification")
    }
  }

  FileView {
    id: store
    path: sounds.path
    onLoaded: {
      try {
        const data = JSON.parse(text())
        sounds.fx = data.fx !== false
        sounds.ambience = data.ambience !== false
        if (typeof data.volume === "number") sounds.volume = Math.max(0, Math.min(1, data.volume))
      } catch (error) {
        console.warn("cyberdeck: unreadable sound settings: " + error)
      }
    }
  }
}
