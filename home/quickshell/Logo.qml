import QtQuick
import QtQuick.Effects

// Official corporation logo, stored as a white alpha mask and tinted live.
Item {
  id: logo

  property string corp: ""
  property bool mark: false
  property color color: Theme.primary
  property real glow: 0

  readonly property var marks: ({ arasaka: "arasaka-mark", militech: "militech-mark", tetratronic: "tetratronic-mark" })
  readonly property string file: corp === "" ? "" : (mark && marks[corp] ? marks[corp] : corp)
  readonly property real ratio: img.implicitHeight > 0 ? img.implicitWidth / img.implicitHeight : 1

  implicitHeight: 32
  implicitWidth: height * ratio

  Image {
    id: img
    anchors.fill: parent
    source: logo.file !== "" ? Qt.resolvedUrl("assets/logos/" + logo.file + ".png") : ""
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    smooth: true
    mipmap: true
    visible: false
  }

  MultiEffect {
    anchors.fill: img
    source: img
    visible: img.status === Image.Ready
    colorization: 1
    colorizationColor: logo.color
    shadowEnabled: logo.glow > 0
    shadowColor: logo.color
    shadowBlur: logo.glow
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
  }
}
