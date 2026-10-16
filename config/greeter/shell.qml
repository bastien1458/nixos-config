import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

// Login screen started by greetd inside a throwaway niri session.
// Shares the components and the palette of the user shell.
ShellRoot {
  id: greeter

  property var config: ({ user: "", sessions: [{ name: "NIRI", command: ["niri-session"] }] })
  property string user: ""
  property string password: ""
  property int session: 0
  property string status: "boot"
  property string message: ""
  property int failures: 0

  readonly property var sessions: config.sessions || []

  signal denied()

  function login() {
    if (status === "checking" || status === "granted" || user === "") return
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

  FileView {
    path: Quickshell.env("CYBERDECK_GREETER") || ""
    blockLoading: true
    onLoaded: {
      try {
        greeter.config = JSON.parse(text())
        greeter.user = greeter.config.user || ""
      } catch (error) {
        console.warn("greeter: bad config " + error)
      }
    }
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (responseRequired) Greetd.respond(greeter.password)
      else if (error) greeter.message = message
    }

    function onAuthFailure(message) {
      greeter.fail("ACCESS DENIED")
    }

    function onReadyToLaunch() {
      greeter.status = "granted"
      launchTimer.start()
    }

    function onError(error) {
      greeter.fail("GREETD ERROR // " + error)
    }
  }

  Timer {
    id: launchTimer
    interval: 1100
    onTriggered: Greetd.launch(greeter.sessions[greeter.session].command)
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
      WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      GreeterView {
        anchors.fill: parent
        greeter: greeter
        primary: window.primary
      }
    }
  }
}
