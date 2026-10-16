import QtQuick
import QtQuick.Effects
import Quickshell

Item {
  id: view

  property var greeter
  property bool primary: true
  property real panel: 0
  property real shake: 0
  property real granted: 0

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

  focus: true
  Component.onCompleted: {
    forceActiveFocus()
    power.start()
  }

  Keys.onPressed: (event) => greeter.key(event)

  Connections {
    target: view.greeter
    function onDenied() { deniedAnim.restart() }
    function onBootSkipped() { power.skip() }
    function onStatusChanged() {
      if (view.greeter.status === "granted") grantedAnim.start()
      if (view.greeter.status !== "boot" && view.panel === 0 && !panelAnim.running) panelAnim.start()
    }
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
    opacity: 0.08 * view.panel
    property color tone: Theme.primary
    onToneChanged: requestPaint()
    onPaint: {
      const ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.fillStyle = tone
      for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
    }
  }

  // ---------------------------------------------- cold boot

  PowerOn {
    id: power
    anchors.fill: parent
    opacity: 1 - view.panel
    visible: opacity > 0
    lines: view.boot
    title: Theme.osInfo.name || "CYBERDECK"
    subtitle: "NET ACCESS TERMINAL // " + (view.greeter.config.host || "NIXOS").toUpperCase()
    onFinished: view.greeter.finishBoot()
  }

  MouseArea {
    anchors.fill: parent
    enabled: view.greeter.status === "boot"
    onClicked: view.greeter.finishBoot()
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

  component Field: Item {
    id: fieldBox
    property var greeter
    property color tone
    property string name: ""
    property string label: ""
    property string value: ""
    property bool secret: false
    readonly property bool active: greeter.field === name && !greeter.busy
    width: parent.width
    height: 64

    Rectangle {
      anchors.fill: parent
      color: Theme.alpha(fieldBox.tone, fieldBox.active ? 0.1 : 0.03)
      border.color: Theme.alpha(fieldBox.tone, fieldBox.active ? 0.9 : 0.25)
      border.width: 1
    }

    Rectangle {
      width: 3
      height: parent.height
      color: fieldBox.tone
      visible: fieldBox.active
    }

    Text {
      x: 14
      y: 8
      text: (fieldBox.active ? "▶ " : "") + fieldBox.label
      color: fieldBox.active ? fieldBox.tone : Theme.subtle
      font.family: Theme.fontMono
      font.pixelSize: 10
      font.letterSpacing: 1
    }

    Row {
      x: 14
      y: 26
      spacing: 4
      height: 26

      Text {
        visible: !fieldBox.secret
        anchors.verticalCenter: parent.verticalCenter
        text: fieldBox.value.toUpperCase()
        color: Theme.fg
        font.family: Theme.fontUi
        font.pixelSize: 24
        font.weight: Font.Bold
        font.letterSpacing: 2
      }

      Repeater {
        model: fieldBox.secret ? Math.min(fieldBox.value.length, 30) : 0
        delegate: Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 11
          height: 20
          color: fieldBox.tone
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 11
        height: 20
        color: "transparent"
        border.color: fieldBox.tone
        border.width: 1
        visible: fieldBox.active

        SequentialAnimation on opacity {
          loops: Animation.Infinite
          running: fieldBox.active
          NumberAnimation { to: 0.15; duration: 500 }
          NumberAnimation { to: 1; duration: 500 }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.IBeamCursor
      onClicked: fieldBox.greeter.focusField(fieldBox.name)
    }
  }

  Item {
    id: terminal
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: view.shake
    width: 600
    height: 380
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
      y: 52
      width: parent.width - 56
      spacing: 10

      Field {
        greeter: view.greeter
        tone: view.stateTone
        name: "user"
        label: "NETRUNNER ID"
        value: view.greeter.user
      }

      Field {
        greeter: view.greeter
        tone: view.stateTone
        name: "password"
        label: "PASSPHRASE"
        value: view.greeter.password
        secret: true
      }

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
              : view.greeter.field === "user" ? "ENTER YOUR NETRUNNER ID, THEN ENTER"
              : "TYPE YOUR PASSPHRASE, ENTER TO JACK IN"
        color: view.greeter.status === "idle" || view.greeter.status === "boot" ? Theme.subtle : view.stateTone
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
    opacity: view.panel * (1 - view.granted)

    Repeater {
      model: [
        { label: "REBOOT", icon: "refresh", command: ["systemctl", "reboot"] },
        { label: "POWER OFF", icon: "power", command: ["systemctl", "poweroff"] }
      ]
      delegate: Item {
        id: powerButton
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
          Icon { anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; name: powerButton.modelData.icon; color: Theme.danger }
          Text { text: powerButton.modelData.label; color: Theme.danger; font.family: Theme.fontUi; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 1 }
        }

        MouseArea {
          id: powerArea
          anchors.fill: parent
          hoverEnabled: true
          enabled: view.panel > 0.5
          onClicked: Quickshell.execDetached(powerButton.modelData.command)
        }
      }
    }
  }

  MicroText {
    x: 60
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 44
    text: "TAB / CLICK: SWITCH FIELD // ENTER: NEXT, THEN JACK IN // F2: SESSION // ESC: CLEAR\nUNAUTHORIZED ACCESS IS A CLASS-A NETCRIME UNDER THE NETWATCH CHARTER"
    lineHeight: 1.3
    opacity: view.panel * (1 - view.granted)
  }
}
