import QtQuick
import Quickshell
import Quickshell.Wayland

// The "OS reboot" played on every output while the palette morphs.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window

    required property var modelData
    property real t: 0
    property string label: ""

    screen: modelData
    visible: t > 0
    color: "transparent"
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "cyberdeck-reboot"
    WlrLayershell.layer: WlrLayer.Overlay

    Connections {
      target: Theme
      function onSwitchingChanged() {
        if (!Theme.switching) return
        const entry = Theme.entry(Theme.pendingOs)
        window.label = entry ? entry.name : Theme.pendingOs.toUpperCase()
        run.restart()
      }
    }

    SequentialAnimation {
      id: run
      NumberAnimation { target: window; property: "t"; from: 0; to: 1; duration: 1500; easing.type: Easing.Linear }
      ScriptAction { script: window.t = 0 }
    }

    readonly property real burst: t < 0.15 ? t / 0.15 : (t > 0.75 ? (1 - t) / 0.25 : 1)

    // tearing bands
    Repeater {
      model: 14
      delegate: Rectangle {
        required property int index
        readonly property real seed: (index * 7919 % 97) / 97
        x: (seed - 0.5) * 140 * window.burst + Math.sin(window.t * 40 + index) * 30
        y: window.height * ((seed + window.t * (0.6 + seed)) % 1)
        width: window.width * (0.25 + seed * 0.7)
        height: 2 + seed * 18
        color: index % 3 === 0 ? Theme.danger : (index % 3 === 1 ? Theme.primary : Theme.secondary)
        opacity: 0.35 * window.burst
      }
    }

    // scan sweep
    Rectangle {
      width: parent.width
      height: 3
      y: parent.height * window.t
      color: Theme.primary
      opacity: window.burst
    }

    Item {
      anchors.centerIn: parent
      width: 640
      height: 120
      opacity: window.burst

      Plate {
        anchors.fill: parent
        cut: 18
        cutBL: 10
        fill: Theme.alpha(Theme.bg, 0.92)
        stroke: Theme.primary
        strokeW: 1.5
      }

      Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "OS REBOOT // FLASHING CYBERWARE"
          color: Theme.subtle
          font.family: Theme.fontMono
          font.pixelSize: 11
          font.letterSpacing: 2
        }

        DecodeText {
          anchors.horizontalCenter: parent.horizontalCenter
          source: window.label
          duration: 700
          color: Theme.primary
          font.family: Theme.fontUi
          font.pixelSize: 30
          font.weight: Font.Bold
          font.letterSpacing: 3
        }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 420
          height: 4
          color: Theme.primaryDeep

          Rectangle {
            width: parent.width * Math.min(1, window.t * 1.3)
            height: parent.height
            color: Theme.primary
          }
        }
      }
    }
  }
}
