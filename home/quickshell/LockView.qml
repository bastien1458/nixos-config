import QtQuick
import QtQuick.Effects
import Quickshell

// What a locked monitor shows. Typing goes to the Lock singleton.
Item {
  id: view

  property string screenName: ""
  property real intro: 0
  property real shake: 0
  property real granted: 0

  readonly property string user: (Quickshell.env("USER") || "netrunner").toUpperCase()
  readonly property color stateTone: Lock.status === "denied" ? Theme.danger : Lock.status === "granted" ? Theme.ok : Lock.status === "checking" ? Theme.warn : Theme.primary
  readonly property int trace: Math.min(100, Lock.failures * 17)

  focus: true
  Component.onCompleted: {
    forceActiveFocus()
    introAnim.start()
  }

  Keys.onPressed: (event) => {
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Lock.submit()
    else if (event.key === Qt.Key_Backspace) Lock.erase()
    else if (event.key === Qt.Key_Escape) Lock.buffer = ""
    else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) Lock.type(event.text)
    event.accepted = true
  }

  Connections {
    target: Lock
    function onDenied() { deniedAnim.restart() }
    function onGranted() { grantedAnim.restart() }
  }

  NumberAnimation { id: introAnim; target: view; property: "intro"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }

  SequentialAnimation {
    id: deniedAnim
    NumberAnimation { target: view; property: "shake"; to: 18; duration: 40 }
    NumberAnimation { target: view; property: "shake"; to: -14; duration: 50 }
    NumberAnimation { target: view; property: "shake"; to: 9; duration: 50 }
    NumberAnimation { target: view; property: "shake"; to: -4; duration: 50 }
    NumberAnimation { target: view; property: "shake"; to: 0; duration: 60 }
  }

  NumberAnimation { id: grantedAnim; target: view; property: "granted"; from: 0; to: 1; duration: 900; easing.type: Easing.InCubic }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  // ---------------------------------------------- backdrop

  Image {
    id: wall
    anchors.fill: parent
    source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
    fillMode: Image.PreserveAspectCrop
    sourceSize: Qt.size(1280, 720)
    asynchronous: true
    visible: false
  }

  MultiEffect {
    anchors.fill: wall
    source: wall
    blurEnabled: true
    blur: 0.8
    blurMax: 48
    brightness: -0.35
    saturation: -0.2
    colorization: 0.35
    colorizationColor: Theme.bg
    opacity: view.intro * (1 - view.granted)
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: Theme.alpha(Theme.bg, 0.55) }
      GradientStop { position: 0.5; color: Theme.alpha(Theme.bg, 0.2) }
      GradientStop { position: 1.0; color: Theme.alpha(Theme.bg, 0.85) }
    }
    opacity: 1 - view.granted
  }

  Canvas {
    id: lines
    anchors.fill: parent
    opacity: 0.07
    property color tone: Theme.primary
    onToneChanged: requestPaint()
    onPaint: {
      const ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.fillStyle = tone
      for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
    }
  }

  // ---------------------------------------------- corner hud

  Column {
    x: 40
    y: 36
    spacing: 4
    opacity: view.intro * (1 - view.granted)

    Row {
      spacing: 12

      Logo {
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        corp: "netwatch"
        color: Theme.primary
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "NETWATCH SECURE LINK // SESSION FROZEN"
        color: Theme.primary
        font.family: Theme.fontUi
        font.pixelSize: 18
        font.weight: Font.Bold
        font.letterSpacing: 2
      }
    }

    MicroText {
      text: "LOCKED " + Qt.formatDateTime(Lock.lockedAt, "HH:mm:ss") + " // OUTPUT " + view.screenName + " // ICE: BLACK ICE MK.III"
    }
  }

  GlitchText {
    anchors.right: parent.right
    anchors.rightMargin: 40
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 30
    text: Blackwall.current !== "" ? Blackwall.current : "THE WALL IS LISTENING"
    color: Theme.alpha(Theme.danger, 0.4)
    font.family: Theme.fontMono
    font.pixelSize: 10
    font.letterSpacing: 2
    minGap: 4000
    maxGap: 12000
    opacity: view.intro * (1 - view.granted)
  }

  MicroText {
    x: 40
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 30
    text: "UNAUTHORIZED ACCESS WILL BE TRACED AND REPORTED TO NETWATCH\nPROTOCOL 6520-A44 // " + (Theme.osInfo.name || "")
    lineHeight: 1.3
    opacity: view.intro * (1 - view.granted)
  }

  // ---------------------------------------------- centre

  Column {
    id: centre
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: view.shake
    spacing: 14
    opacity: view.intro * (1 - view.granted)
    scale: 1 + view.granted * 0.06

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: Theme.warn
      font.family: Theme.fontUi
      font.pixelSize: 150
      font.weight: Font.Bold
      font.letterSpacing: 4
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDateTime(clock.date, "dddd dd MMMM yyyy").toUpperCase() + "  //  " + Qt.formatDateTime(clock.date, "ss")
      color: Theme.fg
      font.family: Theme.fontUi
      font.pixelSize: 20
      font.weight: Font.DemiBold
      font.letterSpacing: 4
    }

    Item { width: 1; height: 30 }

    // passphrase box
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 520
      height: 112

      Plate {
        anchors.fill: parent
        cut: 18
        cutBL: 10
        fill: Theme.alpha(Theme.bg, 0.88)
        stroke: view.stateTone
        strokeW: 1.5
        Behavior on stroke { ColorAnimation { duration: 160 } }
      }

      Rectangle {
        x: 0
        y: 16
        width: 3
        height: parent.height - 32
        color: view.stateTone
      }

      Row {
        x: 22
        y: 14
        spacing: 10

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          width: 18
          height: 18
          name: Lock.status === "granted" ? "unlock" : "lock"
          color: view.stateTone
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "ENTER PASSPHRASE // " + view.user
          color: view.stateTone
          font.family: Theme.fontUi
          font.pixelSize: 17
          font.weight: Font.Bold
          font.letterSpacing: 1.5
        }
      }

      // one segment per typed character, like the RAM bar
      Row {
        x: 22
        y: 48
        spacing: 4

        Repeater {
          model: Math.min(Lock.buffer.length, 28)
          delegate: Rectangle {
            width: 12
            height: 22
            color: view.stateTone
          }
        }

        Rectangle {
          id: caret
          width: 12
          height: 22
          color: "transparent"
          border.color: view.stateTone
          border.width: 1
          visible: Lock.status !== "granted"

          SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: Lock.locked
            NumberAnimation { to: 0.15; duration: 500 }
            NumberAnimation { to: 1; duration: 500 }
          }
        }
      }

      DecodeText {
        x: 22
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        source: Lock.status === "checking" ? "AUTHENTICATING WITH NETWATCH..."
              : Lock.status === "denied" ? "ACCESS DENIED // TRACE " + view.trace + "%"
              : Lock.status === "granted" ? "ACCESS GRANTED // WELCOME BACK, " + view.user
              : Lock.failures > 0 ? "ATTEMPT " + (Lock.failures + 1) + " // TRACE " + view.trace + "%"
              : "AWAITING CREDENTIALS"
        color: Lock.status === "idle" ? Theme.subtle : view.stateTone
        font.family: Theme.fontUi
        font.pixelSize: 13
        font.weight: Font.Bold
        font.letterSpacing: 2
      }

      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 15
        width: 120
        height: 4
        visible: Lock.failures > 0
        color: Theme.alpha(Theme.danger, 0.2)

        Rectangle {
          width: parent.width * view.trace / 100
          height: parent.height
          color: Theme.danger
          Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
      }

      Brackets {
        anchors.fill: parent
        anchors.margins: -10
        tone: Theme.alpha(view.stateTone, 0.6)
        len: 16
      }
    }

    // now playing
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8
      visible: Media.active
      opacity: 0.8

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        name: Media.playing ? "music" : "pause"
        color: Theme.secondary
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Media.title.toUpperCase() + (Media.artist !== "" ? "  //  " + Media.artist.toUpperCase() : "")
        color: Theme.secondary
        font.family: Theme.fontUi
        font.pixelSize: 14
        font.weight: Font.DemiBold
        font.letterSpacing: 1
      }
    }
  }

  // access granted flash
  Rectangle {
    anchors.fill: parent
    color: Theme.ok
    opacity: view.granted > 0 ? 0.12 * (1 - view.granted) : 0
  }
}
