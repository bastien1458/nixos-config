import QtQuick

// Keyboard hint box, outlined like in the game footer.
Rectangle {
  id: cap

  property string label: ""
  property color tone: Theme.primary

  implicitWidth: Math.max(26, capText.implicitWidth + 12)
  implicitHeight: 24
  color: Theme.alpha(Theme.bg, 0.8)
  border.color: tone
  border.width: 1

  Text {
    id: capText
    anchors.centerIn: parent
    text: cap.label
    color: cap.tone
    font.family: Theme.fontUi
    font.pixelSize: 14
    font.weight: Font.Bold
  }
}
