pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player worth showing: the one playing, else the last one touched.
Singleton {
  id: media

  readonly property var players: Mpris.players.values
  property var pinned: null
  readonly property var player: {
    const list = players
    if (pinned && list.indexOf(pinned) >= 0) return pinned
    return list.find(p => p.isPlaying) || (list.length > 0 ? list[0] : null)
  }
  readonly property bool active: player !== null
  readonly property bool playing: active && player.isPlaying
  readonly property string title: active ? (player.trackTitle || "UNKNOWN TRACK") : "NO SIGNAL"
  readonly property string artist: active ? (player.trackArtist || player.identity || "") : ""
  readonly property string art: active ? (player.trackArtUrl || "") : ""
  readonly property real length: active && player.lengthSupported ? player.length : 0
  property real position: 0

  function cycle() {
    const list = players
    if (list.length < 2) return
    pinned = list[(list.indexOf(player) + 1) % list.length]
  }

  function format(seconds) {
    const s = Math.max(0, Math.floor(seconds))
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
  }

  // Mpris does not push position updates: sample it while something plays
  Timer {
    interval: 1000
    repeat: true
    running: media.playing && Hud.ccOpen
    triggeredOnStart: true
    onTriggered: media.position = media.player ? media.player.position : 0
  }

  onPlayerChanged: position = player ? player.position : 0
}
