pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active OS palette. Every colour is animated, so switching OS from the
// bar morphs the whole shell instead of snapping.
Singleton {
  id: theme

  // ------------------------------------------------------------ paths

  readonly property string home: Quickshell.env("HOME") || "/tmp"
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/cyberdeck"
  readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/cyberdeck/config.json"
  readonly property string themePath: Quickshell.env("CYBERDECK_THEME") || stateDir + "/theme.json"

  // ------------------------------------------------------------ data

  property var config: ({})
  property var catalog: []
  property string os: "netwatch"
  property var osInfo: ({ name: "NETWATCH NETDRIVER MK.5", short: "NETDRIVER", maker: "NETWATCH", "class": "CYBERDECK", tier: "LEGENDARY", tagline: "FAITHFUL SCAN" })
  property string wallpaper: ""
  property real stamp: 0

  property bool switching: false
  property string pendingOs: ""
  // what the running flash is about, shown by the reboot overlay
  property string pendingLabel: ""
  property string pendingKind: ""
  // last failure of the colour engine, empty when the wall simply refused
  property string lastError: ""
  // every wallpaper known to the engine, see refreshWallpapers()
  property var wallpapers: []

  signal rebooted(string os)
  signal denied(string os)

  // ------------------------------------------------------------ palette

  // no morph until the first palette is in: the shell starts in its real colours
  property bool ready: false
  readonly property int morph: ready ? 1100 : 0

  property color bg: "#070e1c"
  property color surface: "#0f1727"
  property color overlay: "#1a2437"
  property color muted: "#586377"
  property color subtle: "#a79aa3"
  property color fg: "#e9dde6"
  property color bright: "#f5edf3"
  property color white: "#fdf9fb"
  property color primary: "#60b5ff"
  property color secondary: "#e08dce"
  property color tertiary: "#b490e8"
  property color danger: "#ea6b60"
  property color alt: "#f28e42"
  property color warn: "#d5bf36"
  property color ok: "#68c36d"

  Behavior on bg { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on surface { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on overlay { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on muted { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on subtle { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on fg { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on bright { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on white { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on primary { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on secondary { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on tertiary { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on danger { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on alt { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on warn { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }
  Behavior on ok { ColorAnimation { duration: theme.morph; easing.type: Easing.InOutCubic } }

  // derived tones, they follow the animation for free
  readonly property color panel: alpha(bg, 0.94)
  readonly property color panelSoft: alpha(bg, 0.78)
  readonly property color frame: mix(primary, bg, 0.45)
  readonly property color frameDim: mix(primary, bg, 0.72)
  readonly property color primaryDeep: mix(primary, bg, 0.84)
  readonly property color chrome: secondary
  readonly property color chromeDim: mix(secondary, bg, 0.55)
  readonly property color chromeDeep: mix(secondary, bg, 0.85)

  // ------------------------------------------------------------ type

  readonly property string fontUi: "Rajdhani"
  readonly property string fontMono: "JetBrains Mono"

  // ------------------------------------------------------------ helpers

  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
  }

  function roleOf(entry, role) {
    return entry && entry.roles && entry.roles[role] ? entry.roles[role] : primary
  }

  function load(text) {
    let data
    try {
      data = JSON.parse(text)
    } catch (error) {
      console.warn("cyberdeck: unreadable theme " + themePath + ": " + error)
      return
    }
    const roles = data.palette && data.palette.roles
    if (!roles) return
    const changed = data.os !== os && stamp > 0
    bg = roles.bg
    surface = roles.surface
    overlay = roles.overlay
    muted = roles.muted
    subtle = roles.subtle
    fg = roles.fg
    bright = roles.bright
    white = roles.white
    primary = roles.primary
    secondary = roles.secondary
    tertiary = roles.tertiary
    danger = roles.danger
    alt = roles.alt
    warn = roles.warn
    ok = roles.ok
    catalog = data.catalog || []
    os = data.os || "netwatch"
    osInfo = data.palette
    wallpaper = data.wallpaper || ""
    stamp = data.stamp || 1
    if (changed) rebooted(os)
    if (!ready) Qt.callLater(() => theme.ready = true)
  }

  function reload() {
    themeFile.reload()
  }

  function entry(id) {
    return catalog.find(e => e.id === id) || null
  }

  // absolute paths written by home-manager into config.json, bare names as a fallback
  readonly property var fallbackBin: ({ quickshell: "quickshell", theme: "cyberdeck-theme", engrave: "cyberdeck-engrave", lock: "cyberdeck-lock", kitty: "kitty", niri: "niri", pwplay: "pw-play", pavucontrol: "pavucontrol" })

  function bin(name) {
    return (config.bin && config.bin[name]) || fallbackBin[name] || name
  }

  // runs the colour engine; the palette morphs when theme.json is rewritten
  function switchTo(id) {
    if (switching || id === os) return
    if (id === "blackwall" && !Stats.blackwall) {
      lastError = ""
      denied(id)
      return
    }
    const e = entry(id)
    flash(id, "os", e ? e.name : id.toUpperCase(), ["apply", id])
  }

  // same engine, new optics: the palette is recomputed for the new wallpaper
  function setWallpaper(path) {
    if (switching || path === "" || path === wallpaper) return
    flash(os, "wallpaper", path.split("/").pop().replace(/\.[^.]+$/, "").toUpperCase(), ["wallpaper", "set", path])
  }

  function refreshWallpapers() {
    if (!lister.running) lister.running = true
  }

  function flash(id, kind, label, args) {
    pendingOs = id
    pendingKind = kind
    pendingLabel = label
    lastError = ""
    switching = true
    switcher.reported = false
    switcher.command = [bin("theme")].concat(args)
    switcher.running = true
    watchdog.restart()
  }

  function settle(ok, reason) {
    if (!switching) return
    watchdog.stop()
    switching = false
    if (!ok) {
      lastError = reason
      denied(pendingOs)
    }
    themeFile.reload()
    refreshWallpapers()
  }

  Process {
    id: switcher
    // true once exited() came in for the current run
    property bool reported: false
    stderr: StdioCollector { id: switchErrors }
    onStarted: reported = false
    onExited: (code) => {
      reported = true
      const lines = switchErrors.text.trim().split("\n").filter(l => l !== "")
      const reason = lines.length > 0 ? lines[lines.length - 1].replace(/^cyberdeck-theme: /, "") : "the colour engine crashed"
      theme.settle(code === 0, reason.toUpperCase())
    }
    // a binary that cannot be started never emits exited, only running drops back
    onRunningChanged: if (!running && !reported) theme.settle(false, "COLOUR ENGINE NOT FOUND // " + theme.bin("theme").toUpperCase())
  }

  // never stay stuck on INSTALLING: give up on an engine that hangs
  Timer {
    id: watchdog
    interval: 30000
    onTriggered: {
      switcher.running = false
      theme.settle(false, "COLOUR ENGINE TIMED OUT")
    }
  }

  Process {
    id: lister
    command: [theme.bin("theme"), "wallpapers"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          theme.wallpapers = JSON.parse(this.text)
        } catch (error) {
          console.warn("cyberdeck: unreadable wallpaper list: " + error)
        }
      }
    }
  }

  FileView {
    id: themeFile
    path: theme.themePath
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: theme.load(text())
  }

  FileView {
    id: configFile
    path: theme.configPath
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        theme.config = JSON.parse(text())
      } catch (error) {
        console.warn("cyberdeck: unreadable config " + theme.configPath + ": " + error)
      }
    }
  }
}
