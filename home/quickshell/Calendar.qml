import QtQuick

// Month grid, monday first, with month navigation.
Item {
  id: cal

  property date today: new Date()
  property int offset: 0
  readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
  readonly property var cells: build(shown)
  readonly property real cellW: width / 7

  implicitHeight: 34 + 18 + 6 * 22

  function build(first) {
    const year = first.getFullYear()
    const month = first.getMonth()
    const lead = (first.getDay() + 6) % 7
    const out = []
    for (let i = 0; i < 42; i++) {
      const d = new Date(year, month, i - lead + 1)
      out.push({
        day: d.getDate(),
        inside: d.getMonth() === month,
        today: d.toDateString() === cal.today.toDateString(),
        weekend: d.getDay() === 0 || d.getDay() === 6
      })
    }
    return out
  }

  Row {
    width: parent.width
    height: 28

    Item {
      width: 24
      height: 28

      Icon { anchors.centerIn: parent; width: 14; height: 14; name: "left"; color: Theme.primary; weight: 2 }

      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cal.offset-- }
    }

    Item {
      width: parent.width - 48
      height: 28

      Text {
        anchors.centerIn: parent
        text: Qt.formatDate(cal.shown, "MMMM yyyy").toUpperCase()
        color: cal.offset === 0 ? Theme.fg : Theme.warn
        font.family: Theme.fontUi
        font.pixelSize: 15
        font.weight: Font.Bold
        font.letterSpacing: 1.5
      }

      MouseArea { anchors.fill: parent; onClicked: cal.offset = 0 }
    }

    Item {
      width: 24
      height: 28

      Icon { anchors.centerIn: parent; width: 14; height: 14; name: "right"; color: Theme.primary; weight: 2 }

      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cal.offset++ }
    }
  }

  Row {
    y: 34
    Repeater {
      model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
      delegate: Text {
        required property string modelData
        required property int index
        width: cal.cellW
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: index >= 5 ? Theme.secondary : Theme.subtle
        font.family: Theme.fontMono
        font.pixelSize: 9
        font.weight: Font.Bold
      }
    }
  }

  Grid {
    y: 52
    columns: 7

    Repeater {
      model: cal.cells
      delegate: Item {
        required property var modelData
        width: cal.cellW
        height: 22

        Rectangle {
          anchors.centerIn: parent
          width: 24
          height: 18
          visible: modelData.today
          color: Theme.primary
        }

        Text {
          anchors.centerIn: parent
          text: modelData.day
          color: modelData.today ? Theme.bg : !modelData.inside ? Theme.alpha(Theme.muted, 0.6) : modelData.weekend ? Theme.secondary : Theme.fg
          font.family: Theme.fontUi
          font.pixelSize: 14
          font.weight: modelData.today ? Font.Bold : Font.DemiBold
        }
      }
    }
  }
}
