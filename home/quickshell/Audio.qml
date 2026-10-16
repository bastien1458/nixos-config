pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink/source and per-application streams, straight from PipeWire.
Singleton {
  id: audio

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property bool ready: sink !== null && sink.audio !== null
  readonly property real volume: ready ? sink.audio.volume : 0
  readonly property bool muted: ready ? sink.audio.muted : true
  readonly property bool micReady: source !== null && source.audio !== null
  readonly property real micVolume: micReady ? source.audio.volume : 0
  readonly property bool micMuted: micReady ? source.audio.muted : true
  readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio && !n.isSink)
  readonly property string icon: muted ? "volume-mute" : (volume < 0.4 ? "volume-low" : "volume")

  function clamp(v) {
    return Math.max(0, Math.min(1, v))
  }

  function setVolume(v) {
    if (!ready) return
    sink.audio.muted = false
    sink.audio.volume = clamp(v)
  }

  function nudge(delta) {
    setVolume(volume + delta)
  }

  function toggleMute() {
    if (ready) sink.audio.muted = !sink.audio.muted
  }

  function setMic(v) {
    if (!micReady) return
    source.audio.muted = false
    source.audio.volume = clamp(v)
  }

  function toggleMic() {
    if (micReady) source.audio.muted = !source.audio.muted
  }

  function nameOf(node) {
    if (!node) return "NO DEVICE"
    const props = node.properties || {}
    return (props["application.name"] || node.nickname || node.description || node.name || "UNKNOWN").toUpperCase()
  }

  // binds the nodes so their volume and mute state stay live
  PwObjectTracker {
    objects: [audio.sink, audio.source].concat(audio.streams)
  }
}
