import QtQuick
import QtQuick.Effects

// App icon rendered as a monochrome hologram, falling back to a glyph.
Item {
  id: holo

  property string source: ""
  property string glyph: ""
  property color tone: Theme.primary
  property real glow: 0
  property int glyphSize: 15

  Image {
    id: holoImage
    anchors.fill: parent
    source: holo.source
    sourceSize: Qt.size(128, 128)
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    smooth: true
    mipmap: true
    visible: false
  }

  MultiEffect {
    anchors.fill: holoImage
    source: holoImage
    visible: holoImage.status === Image.Ready
    colorization: 1
    colorizationColor: holo.tone
    brightness: 0.25
    contrast: 0.25
    shadowEnabled: holo.glow > 0
    shadowColor: holo.tone
    shadowBlur: holo.glow
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
  }

  Text {
    anchors.centerIn: parent
    visible: holoImage.status !== Image.Ready
    text: holo.glyph
    color: holo.tone
    font.family: Theme.fontUi
    font.pixelSize: holo.glyphSize
    font.weight: Font.Bold
    font.letterSpacing: 1
  }
}
