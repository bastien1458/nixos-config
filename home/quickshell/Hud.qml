pragma Singleton

import QtQuick
import Quickshell

// Which overlays are open and on which output. Opening one closes the others.
Singleton {
  id: hud

  property bool ccOpen: false
  property bool osOpen: false
  property bool breachOpen: false
  property string ccOutput: ""
  property string osOutput: ""
  property string breachOutput: ""
  property bool dnd: false
  property bool caffeine: false
  property bool locked: false

  signal quickhackRequested()
  signal glitch()

  function here() {
    return Niri.focusedOutput || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
  }

  function closeAll() {
    ccOpen = false
    osOpen = false
    breachOpen = false
  }

  function toggleCc(output) {
    const target = output || here()
    const reopen = !ccOpen || ccOutput !== target
    closeAll()
    if (reopen) {
      ccOutput = target
      ccOpen = true
    }
  }

  function toggleOs(output) {
    const target = output || here()
    const reopen = !osOpen || osOutput !== target
    closeAll()
    if (reopen) {
      osOutput = target
      osOpen = true
    }
  }

  function openBreach(output) {
    closeAll()
    breachOutput = output || here()
    breachOpen = true
  }

  function screenNamed(name) {
    for (const screen of Quickshell.screens) if (screen.name === name) return screen
    return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
  }
}
