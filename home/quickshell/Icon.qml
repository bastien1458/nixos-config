import QtQuick
import QtQuick.Shapes
import "Glyphs.js" as Glyphs

// Vector icon from Glyphs.js, recoloured live with the theme.
Item {
  id: icon

  property string name: "dot"
  property color color: Theme.fg
  property real weight: 1.8
  property bool emblem: false

  readonly property var glyph: (emblem ? Glyphs.emblems[name] : Glyphs.icons[name]) || Glyphs.icons.dot
  readonly property real grid: emblem ? 64 : 24
  readonly property real k: Math.min(width, height) / grid

  implicitWidth: emblem ? 64 : 18
  implicitHeight: implicitWidth

  Shape {
    x: (icon.width - icon.grid * icon.k) / 2
    y: (icon.height - icon.grid * icon.k) / 2
    width: icon.grid
    height: icon.grid
    scale: icon.k
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: icon.glyph.s ? icon.color : "transparent"
      strokeWidth: icon.weight
      fillColor: "transparent"
      joinStyle: ShapePath.MiterJoin
      capStyle: ShapePath.FlatCap
      PathSvg { path: icon.glyph.s || "M0 0" }
    }

    ShapePath {
      strokeColor: "transparent"
      strokeWidth: 0
      fillColor: icon.glyph.f ? icon.color : "transparent"
      PathSvg { path: icon.glyph.f || "M0 0" }
    }
  }
}
