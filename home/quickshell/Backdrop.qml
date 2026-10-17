import QtQuick
import QtQuick.Effects

// Goes first inside a floating panel: a soft drop shadow and a dark backing
// that also fills the gaps between its sections, so windows never bleed
// through the text. Pass it as the window's blurItem to frost it as well.
Item {
  id: backdrop

  property real pad: 6

  anchors.fill: parent
  anchors.margins: -pad

  RectangularShadow {
    anchors.fill: parent
    visible: Settings.shadows
    offset.y: 10
    blur: 36
    spread: 2
    color: Qt.rgba(0, 0, 0, 0.6)
  }

  Rectangle {
    anchors.fill: parent
    color: Settings.backing
  }
}
