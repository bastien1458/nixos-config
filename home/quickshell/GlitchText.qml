import QtQuick

// Text that tears into chromatic ghosts for a few frames, every now and then.
// Driven by a sparse timer so an idle shell never redraws for nothing.
Item {
  id: glitch

  property alias text: main.text
  property alias color: main.color
  property alias font: main.font
  property alias elide: main.elide
  property bool active: true
  property color ghostA: Theme.danger
  property color ghostB: Theme.primary
  property int minGap: 2500
  property int maxGap: 9000
  property real shift: 0

  implicitWidth: main.implicitWidth
  implicitHeight: main.implicitHeight

  function burst() {
    burstAnim.restart()
  }

  Text {
    text: main.text
    font: main.font
    elide: main.elide
    width: main.width
    color: glitch.ghostA
    x: -glitch.shift
    y: glitch.shift * 0.3
    opacity: glitch.shift !== 0 ? 0.75 : 0
  }

  Text {
    text: main.text
    font: main.font
    elide: main.elide
    width: main.width
    color: glitch.ghostB
    x: glitch.shift
    opacity: glitch.shift !== 0 ? 0.75 : 0
  }

  Text {
    id: main
    width: glitch.width > 0 ? glitch.width : implicitWidth
    x: glitch.shift * 0.4
  }

  Timer {
    running: glitch.active && glitch.visible
    repeat: true
    interval: glitch.minGap
    onTriggered: {
      glitch.burst()
      interval = glitch.minGap + Math.random() * (glitch.maxGap - glitch.minGap)
    }
  }

  SequentialAnimation {
    id: burstAnim
    NumberAnimation { target: glitch; property: "shift"; to: 4; duration: 35 }
    NumberAnimation { target: glitch; property: "shift"; to: -3; duration: 35 }
    NumberAnimation { target: glitch; property: "shift"; to: 2; duration: 30 }
    NumberAnimation { target: glitch; property: "shift"; to: 0; duration: 30 }
  }
}
