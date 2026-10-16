pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

// Session lock (ext-session-lock) with PAM authentication.
// The password buffer lives here so every monitor shows the same input.
Singleton {
  id: lock

  property bool locked: false
  property string buffer: ""
  property string status: "idle"
  property int failures: 0
  property date lockedAt: new Date()

  signal denied()
  signal granted()

  function lock() {
    if (locked) return
    buffer = ""
    status = "idle"
    failures = 0
    lockedAt = new Date()
    Hud.closeAll()
    locked = true
  }

  function type(text) {
    if (status === "checking" || status === "granted") return
    if (status === "denied") status = "idle"
    buffer += text
  }

  function erase() {
    if (status === "checking" || status === "granted") return
    buffer = buffer.slice(0, -1)
  }

  function submit() {
    if (status === "checking" || status === "granted" || buffer.length === 0) return
    status = "checking"
    pam.start()
  }

  function fail() {
    status = "denied"
    failures += 1
    buffer = ""
    denied()
  }

  PamContext {
    id: pam
    config: "cyberlock"

    onPamMessage: {
      if (responseRequired) respond(lock.buffer)
    }

    onCompleted: (result) => {
      if (result === PamResult.Success) {
        lock.status = "granted"
        lock.granted()
        release.start()
      } else {
        lock.fail()
      }
    }

    onError: (error) => {
      console.warn("cyberdeck: pam error " + error)
      lock.fail()
    }
  }

  Timer {
    id: release
    interval: 950
    onTriggered: {
      lock.locked = false
      lock.buffer = ""
      lock.status = "idle"
    }
  }

  WlSessionLock {
    locked: lock.locked

    WlSessionLockSurface {
      id: surface
      color: "#000000"

      LockView {
        anchors.fill: parent
        screenName: surface.screen ? surface.screen.name : ""
      }
    }
  }
}
