import QtQuick
import Quickshell
import Quickshell.Wayland

// Full screen code matrix, opened from the bar, the control center or IPC.
Overlay {
  id: window

  screen: Hud.screenNamed(Hud.breachOutput)
  open: Hud.breachOpen
  openDuration: 420
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "cyberdeck-breach"
  onDismissed: Hud.breachOpen = false
  onOpenChanged: if (open) game.newBreach()

  Rectangle {
    anchors.fill: parent
    color: Theme.alpha(Theme.mix(Theme.bg, Qt.rgba(0, 0, 0, 1), 0.4), 0.9 * window.reveal)
  }

  Rectangle {
    width: parent.width
    height: 140
    y: -height + (parent.height + height) * window.reveal
    visible: window.reveal > 0 && window.reveal < 1
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.alpha(Theme.primary, 0) }
      GradientStop { position: 1.0; color: Theme.alpha(Theme.primary, 0.35) }
    }
  }

  BreachGame {
    id: game
    anchors.fill: parent
    focus: true
    opacity: window.reveal
    onCloseRequested: Hud.breachOpen = false
    onFinished: (earned, perfect, wall, installed) => {
      Stats.record(earned, perfect, wall, installed)
      if (wall) Blackwall.speak("YOU OPENED THE DOOR, " + Blackwall.user)
    }

    // clicks on the game itself must not close the overlay
    MouseArea {
      anchors.fill: parent
      z: -1
      acceptedButtons: Qt.AllButtons
    }
  }
}
