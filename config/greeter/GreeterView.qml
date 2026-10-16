import QtQuick
import QtQuick.Effects
import Quickshell

Item {
  id: view

  property var greeter
  property bool primary: true
  property int bootLine: 0
  property real panel: 0
  property real shake: 0
  property real granted: 0
  property bool editingUser: false

  readonly property var boot: [
    ["NETWATCH BIOS v2.0.77 // (C) 2077 NETWATCH CORP.", "info"],
    ["SYNAPSE CORE ................................ OK", "ok"],
    ["MEMORY CHECK ................................ OK", "ok"],
    ["LOADING CYBERDECK KERNEL .................... OK", "ok"],
    ["MOUNTING DATASHARDS ......................... OK", "ok"],
    ["OPTICS CALIBRATION // KIROSHI ............... OK", "ok"],
    ["WARNING: UNKNOWN TRAFFIC FROM BLACKWALL SECTOR 7 // IGNORED", "warn"],
    ["ICE INTEGRITY ............................... 100%", "ok"],
    ["> JACK IN", "info"]
  ]
  readonly property color stateTone: greeter.status === "denied" ? Theme.danger : greeter.status === "granted" ? Theme.ok : greeter.status === "checking" ? Theme.warn : Theme.primary

  focus: primary
  Component.onCompleted: {
    if (primary) forceActiveFocus()
    bootTimer.start()
  }

  Keys.onPressed: (event) => {
    if (greeter.status === "boot") {
      bootTimer.stop()
      bootLine = boot.length
      finishBoot()
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (editingUser) editingUser = false
      else greeter.login()
    } else if (event.key === Qt.Key_Tab) {
      editingUser = !editingUser
    } else if (event.key === Qt.Key_F2) {
      greeter.session = (greeter.session + 1) % Math.max(1, greeter.sessions.length)
    } else if (event.key === Qt.Key_Backspace) {
      if (editingUser) greeter.user = greeter.user.slice(0, -1)
      else greeter.password = greeter.password.slice(0, -1)
      if (greeter.status === "denied") greeter.status = "idle"
    } else if (event.key === Qt.Key_Escape) {
      greeter.password = ""
    } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
      if (greeter.status === "denied") greeter.status = "idle"
      if (greeter.status === "checking" || greeter.status === "granted") return
      if (editingUser) greeter.user += event.text
      else greeter.password += event.text
    }
    event.accepted = true
  }

  function finishBoot() {
    if (greeter.status === "boot") greeter.status = "idle"
    panelAnim.start()
  }

  Timer {
    id: bootTimer
    interval: 140
    repeat: true
    onTriggered: {
      view.bootLine++
      if (view.bootLine >= view.boot.length) {
        stop()
        settle.start()
      }
    }
  }

  Timer {
    id: settle
    interval: 450
    onTriggered: view.finishBoot()
  }

  Connections {
    target: view.greeter
    function onDenied() { deniedAnim.restart() }
    function onStatusChanged() { if (view.greeter.status === "granted") grantedAnim.start() }
  }

  NumberAnimation { id: panelAnim; target: view; property: "panel"; to: 1; duration: 700; easing.type: Easing.OutCubic }
  NumberAnimation { id: grantedAnim; target: view; property: "granted"; to: 1; duration: 1000; easing.type: Easing.InCubic }

  SequentialAnimation {
    id: deniedAnim
    NumberAnimation { target: view; property: "shake"; to: 16; duration: 40 }
    NumberAnimation { target: view; property: "shake"; to: -12; duration: 50 }
    NumberAnimation { target: view; property: "shake"; to: 7; duration: 50 }
    NumberAnimation { target: view; property: "shake"; to: 0; duration: 60 }
  }

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
    blur: 0.6
    blurMax: 40
    brightness: -0.45
    colorization: 0.4
    colorizationColor: Theme.bg
    opacity: view.panel * (1 - view.granted)
  }

  Canvas {
    anchors.fill: parent
    opacity: 0.08
    onPaint: {
      const ctx = getContext("2d")
      ctx.fillStyle = Theme.primary
      for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
    }
  }

  // ---------------------------------------------- boot log

  Column {
    x: 60
    y: 60
    spacing: 4
    opacity: 1 - view.panel * 0.75

    Repeater {
      model: Math.min(view.bootLine, view.boot.length)
      delegate: Text {
        required property int index
        text: view.boot[index][0]
        color: view.boot[index][1] === "warn" ? Theme.danger : (view.boot[index][1] === "ok" ? Theme.primary : Theme.fg)
        font.family: Theme.fontMono
        font.pixelSize: 14
      }
    }
  }

  // ---------------------------------------------- clock

  Column {
    anchors.right: parent.right
    anchors.rightMargin: 60
    y: 50
    opacity: view.panel * (1 - view.granted)

    Text {
      anchors.right: parent.right
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: Theme.warn
      font.family: Theme.fontUi
      font.pixelSize: 72
      font.weight: Font.Bold
    }

    Text {
      anchors.right: parent.right
      text: Qt.formatDateTime(clock.date, "dddd dd MMMM yyyy").toUpperCase()
      color: Theme.fg
      font.family: Theme.fontUi
      font.pixelSize: 16
      font.weight: Font.DemiBold
      font.letterSpacing: 3
    }
  }

  // ---------------------------------------------- access terminal

  Item {
    id: terminal
    visible: view.primary
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: view.shake
    width: 600
    height: 330
    opacity: view.panel * (1 - view.granted)
    scale: 0.96 + 0.04 * view.panel + view.granted * 0.05

    Plate {
      anchors.fill: parent
      cut: 22
      cutBL: 12
      fill: Theme.alpha(Theme.bg, 0.92)
      stroke: view.stateTone
      strokeW: 1.5
    }

    Rectangle {
      width: parent.width - 22
      height: 34
      color: view.stateTone

      Text {
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "NIGHT CITY // NET ACCESS TERMINAL"
        color: Theme.bg
        font.family: Theme.fontUi
        font.pixelSize: 17
        font.weight: Font.Bold
        font.letterSpacing: 2
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: (view.greeter.config.host || "NIXOS").toUpperCase() + " // PORT 2077"
        color: Theme.alpha(Theme.bg, 0.7)
        font.family: Theme.fontMono
        font.pixelSize: 9
      }
    }

    Column {
      x: 28
      y: 56
      width: parent.width - 56
      spacing: 16

      // netrunner id
      Column {
        spacing: 6

        Text {
          text: "NETRUNNER ID" + (view.editingUser ? "  // EDITING" : "  // TAB TO EDIT")
          color: view.editingUser ? Theme.warn : Theme.subtle
          font.family: Theme.fontMono
          font.pixelSize: 10
          font.letterSpacing: 1
        }

        Row {
          spacing: 10

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            name: "user"
            color: Theme.primary
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (view.greeter.user || "_").toUpperCase() + (view.editingUser ? "█" : "")
            color: Theme.fg
            font.family: Theme.fontUi
            font.pixelSize: 28
            font.weight: Font.Bold
            font.letterSpacing: 2
          }
        }
      }

      // passphrase
      Column {
        spacing: 6

        Text {
          text: "PASSPHRASE"
          color: Theme.subtle
          font.family: Theme.fontMono
          font.pixelSize: 10
          font.letterSpacing: 1
        }

        Row {
          spacing: 4
          height: 22

          Repeater {
            model: Math.min(view.greeter.password.length, 30)
            delegate: Rectangle { width: 12; height: 22; color: view.stateTone }
          }

          Rectangle {
            width: 12
            height: 22
            color: "transparent"
            border.color: view.stateTone
            border.width: 1
            visible: !view.editingUser

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: view.greeter.status !== "granted"
              NumberAnimation { to: 0.15; duration: 500 }
              NumberAnimation { to: 1; duration: 500 }
            }
          }
        }
      }

      // session
      Row {
        spacing: 10

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "SESSION"
          color: Theme.subtle
          font.family: Theme.fontMono
          font.pixelSize: 10
        }

        Chip {
          anchors.verticalCenter: parent.verticalCenter
          label: view.greeter.sessions.length > 0 ? view.greeter.sessions[view.greeter.session].name : "NONE"
          tone: Theme.secondary
          size: 13
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: view.greeter.sessions.length > 1
          text: "F2 TO SWITCH"
          color: Theme.muted
          font.family: Theme.fontMono
          font.pixelSize: 9
        }
      }

      DecodeText {
        source: view.greeter.status === "checking" ? "AUTHENTICATING..."
              : view.greeter.status === "denied" ? view.greeter.message + " // ATTEMPT " + view.greeter.failures
              : view.greeter.status === "granted" ? "ACCESS GRANTED // UPLOADING NEURAL PROFILE"
              : "PRESS ENTER TO JACK IN"
        color: view.greeter.status === "idle" ? Theme.subtle : view.stateTone
        font.family: Theme.fontUi
        font.pixelSize: 15
        font.weight: Font.Bold
        font.letterSpacing: 2
      }
    }

    Brackets {
      anchors.fill: parent
      anchors.margins: -10
      tone: Theme.alpha(view.stateTone, 0.6)
      len: 18
    }
  }

  // ---------------------------------------------- footer

  Row {
    anchors.right: parent.right
    anchors.rightMargin: 60
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40
    spacing: 18
    visible: view.primary
    opacity: view.panel * (1 - view.granted)

    Repeater {
      model: [
        { label: "REBOOT", icon: "refresh", command: ["systemctl", "reboot"] },
        { label: "POWER OFF", icon: "power", command: ["systemctl", "poweroff"] }
      ]
      delegate: Item {
        id: power
        required property var modelData
        width: powerRow.width + 20
        height: 30

        Plate {
          anchors.fill: parent
          cut: 7
          fill: Theme.alpha(Theme.danger, powerArea.containsMouse ? 0.2 : 0.05)
          stroke: Theme.alpha(Theme.danger, 0.6)
        }

        Row {
          id: powerRow
          anchors.centerIn: parent
          spacing: 8
          Icon { anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; name: power.modelData.icon; color: Theme.danger }
          Text { text: power.modelData.label; color: Theme.danger; font.family: Theme.fontUi; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 1 }
        }

        MouseArea {
          id: powerArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: Quickshell.execDetached(power.modelData.command)
        }
      }
    }
  }

  MicroText {
    x: 60
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 44
    text: "TAB: EDIT ID // F2: SESSION // ENTER: JACK IN\nUNAUTHORIZED ACCESS IS A CLASS-A NETCRIME UNDER THE NETWATCH CHARTER"
    lineHeight: 1.3
    opacity: view.panel * (1 - view.granted)
  }
}
