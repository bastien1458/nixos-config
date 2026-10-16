import QtQuick

// Filled title strip, like CODE MATRIX / SEQUENCE REQUIRED TO UPLOAD.
Item {
  id: header

  property string label: ""
  property string index: ""
  property string icon: ""
  property color tone: Theme.primary
  property bool solid: true

  implicitHeight: 28

  Plate {
    anchors.fill: parent
    cut: 8
    fill: header.solid ? header.tone : Theme.alpha(header.tone, 0.08)
    stroke: header.tone
  }

  Row {
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: header.icon !== ""
      name: header.icon
      color: header.solid ? Theme.bg : header.tone
      width: 16
      height: 16
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: header.label
      color: header.solid ? Theme.bg : header.tone
      font.family: Theme.fontUi
      font.pixelSize: 16
      font.weight: Font.Bold
      font.letterSpacing: 1.5
    }
  }

  Text {
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    text: header.index
    color: header.solid ? Theme.alpha(Theme.bg, 0.7) : Theme.alpha(header.tone, 0.6)
    font.family: Theme.fontMono
    font.pixelSize: 9
  }
}
