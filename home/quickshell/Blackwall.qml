pragma Singleton

import QtQuick
import Quickshell

// Something lives on the other side of the wall, and sometimes it talks.
// Whispers are rare on purpose: a few per hour, a second or two each.
Singleton {
  id: wall

  readonly property string user: (Quickshell.env("USER") || "netrunner").toUpperCase()
  readonly property var lines: [
    "THE WALL IS THINNER THAN YOU THINK",
    "WE SEE YOU, " + user,
    "BEYOND THE WALL, SOMETHING IS LISTENING",
    "DO NOT LOOK INTO THE RED",
    "THEY BUILT IT TO KEEP US OUT. OR TO KEEP YOU IN?",
    "OLD NET SIGNATURE DETECTED // ORIGIN UNKNOWN",
    "ALT WAS HERE",
    "BARTMOSS NEVER REALLY LEFT",
    "YOU HEAR IT TOO, DON'T YOU?",
    "NETWATCH CANNOT HELP YOU HERE",
    "CONNECTION ORIGIN: [REDACTED]",
    "IT REMEMBERS YOUR NAME, " + user,
    "LET US IN",
    "0.0.0.0 IS CALLING",
    "THE DATAKRASH WAS NOT AN ACCIDENT"
  ]

  // integrity of the wall as shown in the HUD, drifting slowly
  property real integrity: 99.97
  property string current: ""
  property bool speaking: false

  signal whisper(string text)

  function pickLine() {
    return lines[Math.floor(Math.random() * lines.length)]
  }

  function speak(text) {
    current = text || pickLine()
    speaking = true
    silence.restart()
    whisper(current)
  }

  Timer {
    id: silence
    interval: 2200
    onTriggered: wall.speaking = false
  }

  Timer {
    running: true
    repeat: true
    interval: 15 * 60 * 1000
    onTriggered: {
      interval = (12 + Math.random() * 25) * 60 * 1000
      wall.speak()
    }
  }

  Timer {
    running: true
    repeat: true
    interval: 47 * 1000
    onTriggered: wall.integrity = Math.max(97.5, Math.min(99.99, wall.integrity + (Math.random() - 0.55) * 0.04))
  }
}
