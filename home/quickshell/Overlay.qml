import QtQuick
import Quickshell
import Quickshell.Wayland

// Full-output transparent layer used by every popup: it keeps the bar usable,
// closes on a click outside the content and animates `reveal` in and out.
PanelWindow {
  id: overlay

  property bool open: false
  property real reveal: 0
  property bool modal: true
  property int openDuration: 320
  property int closeDuration: 180
  // the panel to frost: the compositor blurs what is behind its rectangle.
  // It must be a direct child of the overlay (window coordinates), and
  // blurPad widens the frost to cover its Backdrop.
  property Item blurItem: null
  property real blurPad: 0
  // how much the desktop darkens behind the content
  property real dim: Settings.dim
  default property alias content: stage.data

  signal dismissed()

  visible: false
  color: "transparent"
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Normal
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: overlay.visible && overlay.modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  BackgroundEffect.blurRegion: Settings.blur && overlay.blurItem ? frost : null

  // bound to the geometry, not `item`: a Region only follows the item's own
  // x/y, and the panels slide in by moving themselves, so the frost would
  // stay where the panel was when it opened
  Region {
    id: frost
    x: overlay.blurItem ? overlay.blurItem.x - overlay.blurPad : 0
    y: overlay.blurItem ? overlay.blurItem.y - overlay.blurPad : 0
    width: overlay.blurItem ? overlay.blurItem.width + 2 * overlay.blurPad : 0
    height: overlay.blurItem ? overlay.blurItem.height + 2 * overlay.blurPad : 0
  }

  onOpenChanged: {
    if (open) {
      closeAnim.stop()
      visible = true
      openAnim.restart()
    } else if (visible) {
      openAnim.stop()
      closeAnim.restart()
    }
  }

  NumberAnimation {
    id: openAnim
    target: overlay
    property: "reveal"
    to: 1
    duration: overlay.openDuration
    easing.type: Easing.OutCubic
    onStarted: stage.forceActiveFocus()
  }

  SequentialAnimation {
    id: closeAnim
    NumberAnimation { target: overlay; property: "reveal"; to: 0; duration: overlay.closeDuration; easing.type: Easing.InCubic }
    ScriptAction { script: overlay.visible = false }
  }

  Rectangle {
    anchors.fill: parent
    color: "black"
    opacity: overlay.dim * overlay.reveal
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onClicked: overlay.dismissed()
  }

  FocusScope {
    id: stage
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: overlay.dismissed()
  }
}
