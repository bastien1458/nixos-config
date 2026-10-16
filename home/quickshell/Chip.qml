import QtQuick

// READY / TRACEABLE style tag.
Rectangle {
  id: chip

  property string label: ""
  property color tone: Theme.primary
  property bool solid: false
  property bool flashing: false
  property real pulse: 0
  property int size: 12

  implicitWidth: chipText.implicitWidth + 12
  implicitHeight: size + 6
  color: solid ? tone : Theme.alpha(tone, 0.08 + pulse * 0.35)
  border.color: tone
  border.width: 1

  Text {
    id: chipText
    anchors.centerIn: parent
    text: chip.label
    color: chip.solid ? Theme.bg : chip.tone
    font.family: Theme.fontUi
    font.pixelSize: chip.size
    font.weight: Font.Bold
    font.letterSpacing: 1
  }

  SequentialAnimation on pulse {
    running: chip.flashing
    loops: Animation.Infinite
    onRunningChanged: if (!running) chip.pulse = 0
    NumberAnimation { to: 1; duration: 180 }
    NumberAnimation { to: 0; duration: 180 }
  }
}
