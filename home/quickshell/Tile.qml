import QtQuick

// Quick toggle of the control center.
Item {
  id: tile

  property string icon: "dot"
  property string label: ""
  property string hint: ""
  property bool active: false
  property color tone: Theme.primary

  signal clicked()

  implicitWidth: 100
  implicitHeight: 60

  Plate {
    anchors.fill: parent
    cut: 10
    fill: tile.active ? tile.tone : (area.containsMouse ? Theme.alpha(tile.tone, 0.14) : Theme.alpha(tile.tone, 0.05))
    stroke: tile.active ? tile.tone : Theme.alpha(tile.tone, area.containsMouse ? 0.7 : 0.35)
    Behavior on fill { ColorAnimation { duration: 140 } }
  }

  Icon {
    x: 10
    y: 9
    width: 18
    height: 18
    name: tile.icon
    color: tile.active ? Theme.bg : tile.tone
    weight: 1.8
  }

  Column {
    x: 10
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 7
    spacing: -2

    Text {
      width: tile.width - 14
      text: tile.label
      color: tile.active ? Theme.bg : Theme.fg
      fontSizeMode: Text.HorizontalFit
      minimumPixelSize: 9
      font.family: Theme.fontUi
      font.pixelSize: 13
      font.weight: Font.Bold
      font.letterSpacing: 0.5
    }

    Text {
      text: tile.hint
      color: tile.active ? Theme.alpha(Theme.bg, 0.75) : Theme.subtle
      font.family: Theme.fontMono
      font.pixelSize: 8
    }
  }

  Clickable {
    id: area
    anchors.fill: parent
    onClicked: tile.clicked()
  }
}
