pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The soundscape of the deck: UI blips, the city ambience and the breach OST,
// all played through pw-play. Each sound is assets/sounds/<name>.mp3, made
// from the game's own files by cyberdeck-sounds (the breach OST is still a
// placeholder); a <name>.mp3 or .wav in $XDG_DATA_HOME/cyberdeck/sounds wins
// without a rebuild. A missing sound just stays quiet.
Singleton {
  id: sounds

  // kept in $XDG_STATE_HOME/cyberdeck/sound.json, toggled from the control center
  property bool fx: true
  property bool ambience: true
  property real volume: 0.7

  readonly property string dir: decodeURIComponent(Qt.resolvedUrl("assets/sounds").toString().replace(/^file:\/\//, ""))
  readonly property string gameDir: (Quickshell.env("XDG_DATA_HOME") || Theme.home + "/.local/share") + "/cyberdeck/sounds"
  readonly property string path: Theme.stateDir + "/sound.json"
  // name -> file, from both folders
  property var installed: ({})
  property bool scanned: false
  property var waiting: []

  // loudness of each sound before the master volume
  readonly property var levels: ({
    hover: 0.18,
    click: 0.5,
    tab: 0.45,
    "value-up": 0.35,
    "value-down": 0.35,
    "menu-open": 0.55,
    "menu-close": 0.5,
    "radial-open": 0.5,
    "radial-close": 0.45,
    "matrix-hover": 0.25,
    "breach-open": 0.6,
    "breach-success": 0.8,
    "breach-fail": 0.8,
    notification: 0.6,
    call: 0.8,
    "deck-switch": 0.8,
    "lock-denied": 0.7,
    "lock-granted": 0.7,
    boot: 0.9,
    ambient: 0.25,
    breach: 0.45
  })

  // what should be looping right now
  readonly property string loop: Lock.locked ? "" : Hud.breachOpen ? "breach" : ambience ? "ambient" : ""
  readonly property bool menuOpen: Hud.ccOpen || Hud.osOpen || Hud.wallOpen || Hud.settingsOpen
  property var lastPlayed: ({})

  function file(name) {
    return installed[name] || ""
  }

  function has(name) {
    return file(name) !== ""
  }

  function level(name) {
    return (volume * (levels[name] !== undefined ? levels[name] : 0.5)).toFixed(2)
  }

  function play(name) {
    // the boot can beat the scan: hold it until we know which file to use
    if (!scanned) {
      waiting.push(name)
      return
    }
    if (!fx || volume <= 0 || !has(name)) return
    // sweeping the pointer over a list must not turn into a machine gun
    const now = Date.now()
    if (now - (lastPlayed[name] || 0) < 45) return
    lastPlayed[name] = now
    Quickshell.execDetached([Theme.bin("pwplay"), "--volume=" + level(name), file(name)])
  }

  function rescan() {
    scan.running = true
  }

  function found(listing) {
    const files = {}
    for (const line of listing.split("\n")) {
      if (line !== "") files[line.replace(/^.*\//, "").replace(/\.(wav|mp3)$/, "")] = line
    }
    installed = files
    scanned = true
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
    if (loop === "" || !scanned) return
    looper.track = loop
    looper.running = true
  }

  onLoopChanged: sync()
  onScannedChanged: {
    for (const name of waiting) play(name)
    waiting = []
    sync()
  }

  // a menu closing to open another one only sounds the opening
  onMenuOpenChanged: {
    if (menuOpen) {
      menuClosed.stop()
      play("menu-open")
    } else {
      menuClosed.restart()
    }
  }

  Timer {
    id: menuClosed
    interval: 30
    onTriggered: if (!sounds.menuOpen) sounds.play("menu-close")
  }

  Process {
    id: scan
    running: true
    // the repo first, so the local folder overrides it
    command: ["sh", "-c", "for d in \"$0\" \"$1\"; do for f in \"$d\"/*.wav \"$d\"/*.mp3; do [ -f \"$f\" ] && echo \"$f\"; done; done; true", sounds.dir, sounds.gameDir]
    stdout: StdioCollector {
      id: listing
      onStreamFinished: sounds.found(this.text)
    }
    // an empty listing may never finish its stream: never wait on it alone
    onExited: if (!sounds.scanned) sounds.found(listing.text)
  }

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
      if (Calls.isCall(n)) return
      if (!Hud.dnd || Notifs.isCritical(n)) sounds.play("notification")
    }
  }

  // V's ringtone while a call rings; do not disturb lets the holocall show in silence
  readonly property bool ringing: Calls.active && fx && volume > 0 && !Hud.dnd && scanned
  onRingingChanged: {
    if (ringing && !has("call")) play("notification")
    else ringer.running = ringing && has("call")
  }

  Process {
    id: ringer
    command: [Theme.bin("pwplay"), "--volume=" + sounds.level("call"), sounds.file("call")]
    onRunningChanged: if (!running && sounds.ringing) ringAgain.restart()
  }

  Timer {
    id: ringAgain
    interval: 40
    onTriggered: if (sounds.ringing) ringer.running = true
  }

  Connections {
    target: Hud
    function onBreachOpenChanged() {
      if (Hud.breachOpen) sounds.play("breach-open")
    }
  }

  Connections {
    target: Lock
    function onDenied() { sounds.play("lock-denied") }
    function onGranted() { sounds.play("lock-granted") }
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
