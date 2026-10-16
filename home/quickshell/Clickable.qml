import QtQuick

// A MouseArea that sounds like the deck: a tick when the pointer lands on it,
// a click when it is pressed. Empty sound names keep it quiet.
MouseArea {
  id: area

  property string hoverSound: "hover"
  property string clickSound: "click"

  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  // connections rather than handlers: users of the component keep their own
  Connections {
    target: area
    function onContainsMouseChanged() {
      if (area.containsMouse && area.enabled && area.hoverSound !== "") Sounds.play(area.hoverSound)
    }
    function onPressed(mouse) {
      if (area.clickSound !== "") Sounds.play(area.clickSound)
    }
  }
}
