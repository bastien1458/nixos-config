import QtQuick

// Four targeting corners around the parent, like the scanner reticle.
Item {
  id: brackets

  property color tone: Theme.primary
  property real len: 10
  property real thickness: 2
  property real spread: 0

  Repeater {
    model: 4
    delegate: Item {
      required property int index
      readonly property bool atRight: index % 2 === 1
      readonly property bool atBottom: index > 1
      x: atRight ? brackets.width - brackets.len + brackets.spread : -brackets.spread
      y: atBottom ? brackets.height - brackets.len + brackets.spread : -brackets.spread
      width: brackets.len
      height: brackets.len

      Rectangle {
        x: 0
        y: parent.atBottom ? parent.height - height : 0
        width: parent.width
        height: brackets.thickness
        color: brackets.tone
      }

      Rectangle {
        x: parent.atRight ? parent.width - width : 0
        y: 0
        width: brackets.thickness
        height: parent.height
        color: brackets.tone
      }
    }
  }
}
