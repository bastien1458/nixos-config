import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

// Login screen started by greetd inside a throwaway niri session.
// Shares the components and the palette of the user shell. Every output
// shows the same terminal; whichever one has the keyboard drives it.
ShellRoot {
  id: root

  property var config: ({ user: "", sessions: [{ name: "NIRI", command: ["niri-session"] }] })
  property string user: ""
  property string password: ""
  // the field that receives the keys: "user" or "password"
  property string field: "password"
  property int session: 0
  property string status: "boot"
  property string message: ""
  property int failures: 0

  readonly property var sessions: config.sessions || []
  readonly property bool busy: status === "checking" || status === "granted"

  signal denied()
  signal bootSkipped()

  function finishBoot() {
    if (status !== "boot") return
    status = "idle"
    bootSkipped()
  }

  function focusField(name) {
    if (busy) return
    field = name
  }

  function login() {
    if (busy) return
    if (user === "") {
      field = "user"
      fail("NETRUNNER ID REQUIRED")
      return
    }
    // without the greetd socket createSession only logs, keys would stay ignored
    if (!Greetd.available) {
      fail("GREETD OFFLINE")
      return
    }
    status = "checking"
    message = ""
    Greetd.createSession(user)
  }

  function fail(text) {
    status = "denied"
    message = text
    failures += 1
    password = ""
    denied()
    if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession()
  }

  // keys from any output; nothing typed during the boot sequence is lost
  function key(event) {
    if (status === "boot") finishBoot()
    event.accepted = true
    if (busy) return
    const k = event.key
    if (k === Qt.Key_Tab || k === Qt.Key_Backtab || k === Qt.Key_Up || k === Qt.Key_Down) {
      field = field === "user" ? "password" : "user"
    } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
      if (field === "user") field = "password"
      else login()
    } else if (k === Qt.Key_F2) {
      session = (session + 1) % Math.max(1, sessions.length)
    } else if (k === Qt.Key_Backspace) {
      if (field === "user") user = user.slice(0, -1)
      else password = password.slice(0, -1)
      if (status === "denied") status = "idle"
    } else if (k === Qt.Key_Escape) {
      if (field === "user") user = ""
      else password = ""
    } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
      if (status === "denied") status = "idle"
      if (field === "user") user += event.text
      else password += event.text
    }
  }

  FileView {
    path: Quickshell.env("CYBERDECK_GREETER") || ""
    blockLoading: true
    onLoaded: {
      try {
        root.config = JSON.parse(text())
        root.user = root.config.user || ""
        root.field = root.user === "" ? "user" : "password"
      } catch (error) {
        console.warn("greeter: bad config " + error)
      }
    }
  }

  // tells the wrapper script that a session was handed to greetd, so a
  // crash of this greeter afterwards does not start the fallback greeter
  FileView {
    id: marker
    path: Quickshell.env("CYBERDECK_GREETER_MARKER") || ""
    blockWrites: true
    printErrors: false
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (responseRequired) Greetd.respond(root.password)
      else if (error) root.message = message.toUpperCase()
    }

    function onAuthFailure(message) {
      root.fail("ACCESS DENIED")
    }

    function onReadyToLaunch() {
      root.status = "granted"
      launchTimer.start()
    }

    function onError(error) {
      root.fail("GREETD ERROR // " + error.toUpperCase())
    }
  }

  // greetd can drop a session without a word: never stay deaf to the keyboard
  Timer {
    interval: 30000
    running: root.status === "checking"
    onTriggered: root.fail("GREETD TIMEOUT")
  }

  Timer {
    id: launchTimer
    interval: 1100
    onTriggered: {
      if (marker.path !== "") marker.setText("launched\n")
      Greetd.launch(root.sessions[root.session].command)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData
      readonly property bool primary: modelData === Quickshell.screens[0]

      screen: modelData
      color: "#000000"
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "cyberdeck-greeter"
      // niri hands the keyboard to the one on the focused output
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      GreeterView {
        anchors.fill: parent
        // not `greeter: greeter`: inside this delegate the view's own property
        // hides the ids of this file, the view would get itself (undefined)
        greeter: root
        primary: window.primary
      }
    }
  }
}
