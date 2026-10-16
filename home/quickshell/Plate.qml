import QtQuick
import QtQuick.Shapes

// Panel with the chamfered corners used everywhere in the game UI.
Shape {
  id: plate

  property real cut: 10
  property real cutTL: 0
  property real cutBR: 0
  property real cutBL: 0
  property color fill: Theme.panel
  property color stroke: Theme.frame
  property real strokeW: 1

  readonly property real o: strokeW / 2

  preferredRendererType: Shape.CurveRenderer

  ShapePath {
    fillColor: plate.fill
    strokeColor: plate.strokeW > 0 ? plate.stroke : "transparent"
    strokeWidth: Math.max(plate.strokeW, 0.01)
    joinStyle: ShapePath.MiterJoin
    capStyle: ShapePath.FlatCap
    startX: plate.o + plate.cutTL
    startY: plate.o
    PathLine { x: plate.width - plate.o - plate.cut; y: plate.o }
    PathLine { x: plate.width - plate.o; y: plate.o + plate.cut }
    PathLine { x: plate.width - plate.o; y: plate.height - plate.o - plate.cutBR }
    PathLine { x: plate.width - plate.o - plate.cutBR; y: plate.height - plate.o }
    PathLine { x: plate.o + plate.cutBL; y: plate.height - plate.o }
    PathLine { x: plate.o; y: plate.height - plate.o - plate.cutBL }
    PathLine { x: plate.o; y: plate.o + plate.cutTL }
    PathLine { x: plate.o + plate.cutTL; y: plate.o }
  }
}
