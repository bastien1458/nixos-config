import QtQuick
import Quickshell
import Quickshell.Wayland

// Volume OSD, click-through, shown on the focused output for a moment.
PanelWindow {
  id: window

  property bool armed: false
  property real life: 0

  screen: Hud.screenNamed(Hud.here())
  visible: life > 0 && !Lock.locked
  color: "transparent"
  anchors.bottom: true
  margins.bottom: 90
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: 380
  implicitHeight: 74
  mask: Region {}
  WlrLayershell.namespace: "cyberdeck-osd"
  WlrLayershell.layer: WlrLayer.Overlay

  // ignore the values reported while PipeWire starts up
  Timer {
    running: true
    interval: 2500
    onTriggered: window.armed = true
  }

  Connections {
    target: Audio
    function onVolumeChanged() { if (window.armed) pulse.restart() }
    function onMutedChanged() { if (window.armed) pulse.restart() }
  }

  SequentialAnimation {
    id: pulse
    NumberAnimation { target: window; property: "life"; to: 1; duration: 90 }
    PauseAnimation { duration: 1300 }
    NumberAnimation { target: window; property: "life"; to: 0; duration: 260 }
  }

  Item {
    anchors.fill: parent
    opacity: window.life
    transform: Translate { y: (1 - window.life) * 12 }

    Plate {
      anchors.fill: parent
      cut: 14
      cutBL: 8
      fill: Theme.alpha(Theme.bg, 0.94)
      stroke: Audio.muted ? Theme.danger : Theme.primary
    }

    Icon {
      x: 18
      anchors.verticalCenter: parent.verticalCenter
      width: 28
      height: 28
      name: Audio.icon
      color: Audio.muted ? Theme.danger : Theme.primary
    }

    Text {
      x: 60
      y: 12
      text: "SONIC MATRIX // " + Audio.nameOf(Audio.sink)
      color: Theme.subtle
      font.family: Theme.fontMono
      font.pixelSize: 9
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 18
      y: 8
      text: Audio.muted ? "MUTED" : Math.round(Audio.volume * 100)
      color: Audio.muted ? Theme.danger : Theme.fg
      font.family: Theme.fontUi
      font.pixelSize: 20
      font.weight: Font.Bold
    }

    Slider {
      x: 60
      y: 40
      width: parent.width - 78
      height: 16
      segments: 30
      value: Audio.volume
      muted: Audio.muted
      tone: Theme.primary
      enabled: false
    }
  }
}
