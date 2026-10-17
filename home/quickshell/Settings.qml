pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What the SHELL SETTINGS app changes, kept in the state folder so it survives
// rebuilds. Every value has a default: no file is a factory-fresh deck.
Singleton {
  id: settings

  readonly property string path: Theme.stateDir + "/settings.json"

  // the clone nixos-rebuild runs from; empty keeps `dotfiles` of flake.nix
  property string repo: ""
  property int barHeight: 40
  // "top" or "bottom"
  property string barPosition: "top"
  // frost behind the floating panels: niri blurs the wallpaper under them
  property bool blur: true
  property bool shadows: true
  // backing drawn under the panels, the frost shows through what is left
  property real panelOpacity: 0.6
  // darkens the desktop behind the control center and the menus
  property real dim: 0.25
  // empty: located from the IP by wttr.in
  property string weatherLocation: ""
  property bool clockSeconds: false

  readonly property var defaults: ({ repo: "", barHeight: 40, barPosition: "top", blur: true, shadows: true, panelOpacity: 0.6, dim: 0.25, weatherLocation: "", clockSeconds: false })
  readonly property int minBar: 32
  readonly property int maxBar: 56

  readonly property string defaultRepo: Theme.config.repo || ""
  readonly property string rebuildRepo: repo !== "" ? repo : defaultRepo
  readonly property bool barBottom: barPosition === "bottom"
  // the frost only shows through translucent panels; without it they go
  // near opaque again so windows never bleed through the text
  readonly property color backing: Theme.alpha(Theme.bg, blur ? panelOpacity : Math.max(panelOpacity, 0.92))
  // the sections drawn on top of the backing
  readonly property real plateAlpha: blur ? 0.4 : 0.9
  readonly property color plate: Theme.alpha(Theme.bg, plateAlpha)

  function set(key, value) {
    if (settings[key] === value) return
    settings[key] = value
    save()
  }

  function reset() {
    for (const key in defaults) settings[key] = defaults[key]
    save()
  }

  function save() {
    const out = {}
    for (const key in defaults) out[key] = settings[key]
    store.setText(JSON.stringify(out, null, 1) + "\n")
  }

  function load(text) {
    let data = {}
    try {
      data = JSON.parse(text)
    } catch (error) {
      console.warn("cyberdeck: unreadable settings " + settings.path + ": " + error)
      return
    }
    for (const key in defaults) {
      if (data[key] === undefined || typeof data[key] !== typeof defaults[key]) continue
      settings[key] = data[key]
    }
    barHeight = Math.max(minBar, Math.min(maxBar, Math.round(barHeight)))
    if (barPosition !== "top" && barPosition !== "bottom") barPosition = "top"
    panelOpacity = Math.max(0.4, Math.min(1, panelOpacity))
    dim = Math.max(0, Math.min(0.7, dim))
  }

  FileView {
    id: store
    path: settings.path
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: settings.load(text())
  }
}
