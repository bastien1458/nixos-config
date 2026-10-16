import QtQuick

// The deck powering on, CRT style: a line snaps open into a screen, the
// firmware log scrolls, the manufacturer logo locks in and the bar fills up.
// Shared by the greeter (cold boot) and the shell (first login).
Item {
  id: power

  // [text, "ok" | "warn" | "info"]
  property var lines: []
  property string title: Theme.osInfo.name || "CYBERDECK"
  property string subtitle: ""
  property string osId: Theme.os
  property string logo: Theme.osInfo.logo || ""
  property int lineInterval: 85

  property real tube: 0
  property int printed: 0
  property real lock: 0
  property real load: 0

  readonly property bool running: sequence.running || printer.running
  readonly property real tubeW: width * Math.min(1, tube * 2)
  readonly property real tubeH: Math.max(2, height * Math.max(0, tube * 2 - 1))

  signal finished()

  function start() {
    tube = 0
    printed = 0
    lock = 0
    load = 0
    sequence.restart()
  }

  // a key or a click: straight to the end, finished() still fires
  function skip() {
    if (!running) return
    sequence.stop()
    printer.stop()
    tube = 1
    printed = lines.length
    lock = 1
    load = 1
    finished()
  }

  SequentialAnimation {
    id: sequence
    // first a line, then the whole screen
    NumberAnimation { target: power; property: "tube"; to: 0.5; duration: 240; easing.type: Easing.OutQuad }
    NumberAnimation { target: power; property: "tube"; to: 1; duration: 280; easing.type: Easing.OutExpo }
    ScriptAction { script: printer.start() }
    PauseAnimation { duration: Math.max(0, power.lines.length * power.lineInterval - 150) }
    ParallelAnimation {
      NumberAnimation { target: power; property: "lock"; to: 1; duration: 650; easing.type: Easing.OutCubic }
      NumberAnimation { target: power; property: "load"; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
    }
    PauseAnimation { duration: 300 }
    ScriptAction { script: power.finished() }
  }

  Timer {
    id: printer
    interval: power.lineInterval
    repeat: true
    onTriggered: {
      power.printed++
      if (power.printed >= power.lines.length) stop()
    }
  }

  // ---------------------------------------------- the tube

  Item {
    id: crt
    anchors.centerIn: parent
    width: power.tubeW
    height: power.tubeH
    clip: true

    Item {
      x: -crt.x
      y: -crt.y
      width: power.width
      height: power.height

      Rectangle {
        anchors.fill: parent
        color: Theme.mix(Theme.bg, Qt.rgba(0, 0, 0, 1), 0.55)
      }

      Canvas {
        anchors.fill: parent
        opacity: 0.1
        property color tone: Theme.primary
        onToneChanged: requestPaint()
        onPaint: {
          const ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          ctx.fillStyle = tone
          for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
        }
      }

      // firmware log
      Column {
        x: 60
        y: 60
        spacing: 4

        Repeater {
          model: Math.min(power.printed, power.lines.length)
          delegate: Text {
            required property int index
            text: power.lines[index][0]
            color: power.lines[index][1] === "warn" ? Theme.danger : power.lines[index][1] === "ok" ? Theme.primary : Theme.fg
            font.family: Theme.fontMono
            font.pixelSize: 14
          }
        }

        Rectangle {
          visible: power.printed < power.lines.length && power.tube >= 1
          width: 9
          height: 16
          color: Theme.primary
        }
      }

      // the manufacturer locking in
      Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20
        spacing: 14
        opacity: power.lock

        OsBadge {
          anchors.horizontalCenter: parent.horizontalCenter
          width: power.logo === "zetatech" ? 420 : 240
          height: 150
          osId: power.osId
          logo: power.logo
          color: Theme.primary
          weight: 3
          scale: 0.9 + 0.1 * power.lock

          SequentialAnimation on opacity {
            running: power.lock > 0 && power.lock < 1
            loops: 3
            NumberAnimation { to: 0.35; duration: 40 }
            NumberAnimation { to: 1; duration: 70 }
            PauseAnimation { duration: 120 }
          }
        }

        DecodeText {
          anchors.horizontalCenter: parent.horizontalCenter
          source: power.lock > 0 ? power.title : ""
          duration: 600
          color: Theme.fg
          font.family: Theme.fontUi
          font.pixelSize: 34
          font.weight: Font.Bold
          font.letterSpacing: 6
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: power.subtitle
          color: Theme.warn
          font.family: Theme.fontUi
          font.pixelSize: 16
          font.weight: Font.Bold
          font.letterSpacing: 4
        }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 460
          height: 6
          color: Theme.primaryDeep
          border.color: Theme.frame
          border.width: 1

          Rectangle {
            width: parent.width * power.load
            height: parent.height
            color: Theme.primary
          }
        }

        MicroText {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "BOOT SEQUENCE " + Math.round(power.load * 100) + "% // " + (power.osId || "").toUpperCase() + " // V 2.0.77"
          color: Theme.subtle
        }
      }

      // tearing while the tube warms up
      Repeater {
        model: 6
        delegate: Rectangle {
          required property int index
          readonly property real seed: (index * 7919 % 97) / 97
          visible: power.tube < 1
          x: (seed - 0.5) * 80
          y: power.height * ((seed + power.tube * 1.7) % 1)
          width: power.width * (0.3 + seed * 0.6)
          height: 2 + seed * 10
          color: index % 2 === 0 ? Theme.primary : Theme.danger
          opacity: 0.4
        }
      }
    }
  }

  // the hot line of the tube, then a flash when it opens
  Rectangle {
    anchors.centerIn: parent
    width: power.tubeW
    height: 3
    color: Theme.bright
    opacity: power.tube <= 0.5 ? 1 : Math.max(0, 1 - (power.tube - 0.5) * 5)
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.bright
    opacity: power.tube > 0.5 && power.tube < 0.8 ? 0.35 * (1 - Math.abs(power.tube - 0.62) / 0.18) : 0
  }
}
