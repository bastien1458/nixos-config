import QtQuick

// Segmented gauge, like the cyberdeck RAM bar. Click, drag or scroll.
Item {
  id: slider

  property real value: 0
  property color tone: Theme.primary
  property int segments: 24
  property bool muted: false

  signal moved(real value)

  implicitHeight: 14

  function pick(x) {
    nudge(x / width)
  }

  // the game's value tick, once per segment crossed
  function nudge(value) {
    const next = Math.max(0, Math.min(1, value))
    const step = v => Math.round(v * segments)
    if (step(next) !== step(slider.value)) Sounds.play(next > slider.value ? "value-up" : "value-down")
    slider.moved(next)
  }

  Row {
    anchors.fill: parent
    spacing: 2

    Repeater {
      model: slider.segments
      delegate: Rectangle {
        required property int index
        readonly property bool lit: (index + 0.5) / slider.segments <= slider.value
        width: (slider.width - (slider.segments - 1) * 2) / slider.segments
        height: slider.height
        color: lit ? (slider.muted ? Theme.alpha(slider.tone, 0.3) : slider.tone) : Theme.alpha(slider.tone, 0.12)
        Behavior on color { ColorAnimation { duration: 90 } }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -4
    cursorShape: Qt.PointingHandCursor
    onPressed: (mouse) => slider.pick(mouse.x - 4)
    onPositionChanged: (mouse) => { if (pressed) slider.pick(mouse.x - 4) }
    onWheel: (wheel) => slider.nudge(slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
  }
}
