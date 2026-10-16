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
