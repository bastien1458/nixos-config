import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Everything drawn inside the top bar of one output.
Item {
  id: bar

  property string output: ""
  property var window: null

  signal trayMenuRequested(var item, real x)

  readonly property var spaces: Niri.workspacesOn(output)
  readonly property var activeWindow: Niri.activeWindowOn(output)
  readonly property bool focusedHere: Niri.focusedOutput === output

  // ------------------------------------------------------------ pieces

  component Sep: Rectangle {
    width: 1
    height: 14
    color: Theme.frameDim
  }

  component Hover: Clickable {
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
  }

  component Button: Item {
    id: button
    property alias hovered: area.containsMouse
    property color tone: Theme.primary
    default property alias content: inner.data
    signal clicked(var mouse)
    signal wheel(var wheel)
    implicitWidth: inner.implicitWidth + 14
    implicitHeight: 24

    Rectangle {
      anchors.fill: parent
      color: Theme.alpha(button.tone, button.hovered ? 0.14 : 0)
      border.color: Theme.alpha(button.tone, button.hovered ? 0.5 : 0)
      border.width: 1
      Behavior on color { ColorAnimation { duration: 120 } }
    }

    Row {
      id: inner
      anchors.centerIn: parent
      spacing: 6
    }

    Hover {
      id: area
      anchors.fill: parent
      onClicked: (mouse) => button.clicked(mouse)
      onWheel: (wheel) => button.wheel(wheel)
    }
  }

  // ------------------------------------------------------------ frame

  Plate {
    id: frame
    x: 8
    y: 4
    width: parent.width - 16
    height: 32
    cut: 0
    cutBL: 12
    cutBR: 12
    fill: Theme.alpha(Theme.bg, 0.86)
    stroke: Theme.frameDim
  }

  Rectangle {
    x: frame.x + 12
    y: frame.y + frame.height - 2
    width: deck.width + spacesBox.width + 4
    height: 2
    color: Theme.primary
    opacity: bar.focusedHere ? 1 : 0.35
    Behavior on opacity { NumberAnimation { duration: 200 } }
  }

  Rectangle {
    x: frame.x + frame.width - width - 12
    y: frame.y + frame.height - 2
    width: rightGroup.width - 12
    height: 2
    color: Theme.secondary
    opacity: 0.6
  }

  MouseArea {
    anchors.fill: frame
    acceptedButtons: Qt.NoButton
    onWheel: (wheel) => Niri.cycleWorkspace(bar.output, wheel.angleDelta.y < 0 ? 1 : -1)
  }

  // ------------------------------------------------------------ left

  Row {
    id: leftGroup
    x: frame.x + 4
    anchors.verticalCenter: frame.verticalCenter
    spacing: 8

    // opens the quickhack launcher
    Item {
      id: deck
      width: 42
      height: 24

      Plate {
        anchors.fill: parent
        cut: 7
        fill: deckArea.containsMouse ? Theme.mix(Theme.primary, Theme.white, 0.25) : Theme.primary
        strokeW: 0
        Behavior on fill { ColorAnimation { duration: 120 } }
      }

      Icon {
        anchors.centerIn: parent
        width: 16
        height: 16
        name: "chip"
        color: Theme.bg
        weight: 2
      }

      Hover {
        id: deckArea
        anchors.fill: parent
        onClicked: Hud.quickhackRequested()
      }
    }

    // workspaces of this output
    Item {
      id: spacesBox
      anchors.verticalCenter: parent.verticalCenter
      width: spacesRow.width
      height: 24

      Row {
        id: spacesRow
        spacing: 2

        Repeater {
          model: bar.spaces
          delegate: Item {
            id: ws
            required property var modelData
            required property int index
            readonly property bool active: modelData.is_active
            readonly property bool urgent: modelData.is_urgent
            readonly property bool busy: modelData.active_window_id !== null && modelData.active_window_id !== undefined
            width: 30
            height: 24

            Rectangle {
              anchors.fill: parent
              color: ws.active ? Theme.primary : (wsArea.containsMouse ? Theme.alpha(Theme.primary, 0.15) : "transparent")
              Behavior on color { ColorAnimation { duration: 160 } }
            }

            Text {
              anchors.centerIn: parent
              text: String(ws.modelData.idx).padStart(2, "0")
              color: ws.active ? Theme.bg : ws.urgent ? Theme.danger : ws.busy ? Theme.fg : Theme.alpha(Theme.muted, 0.9)
              font.family: Theme.fontUi
              font.pixelSize: 15
              font.weight: Font.Bold
              Behavior on color { ColorAnimation { duration: 160 } }
            }

            Rectangle {
              visible: ws.busy && !ws.active
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              width: 10
              height: 2
              color: Theme.alpha(Theme.primary, 0.6)
            }

            Hover {
              id: wsArea
              anchors.fill: parent
              onClicked: Niri.focusWorkspace(ws.modelData)
            }
          }
        }
      }
    }

    Sep { anchors.verticalCenter: parent.verticalCenter }

    // focused window of this output, or a whisper from beyond the wall
    Item {
      id: titleBox
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(460, Math.max(0, frame.width / 2 - 260 - spacesBox.width))
      height: 24
      clip: true

      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        visible: !Blackwall.speaking
        opacity: bar.focusedHere ? 1 : 0.6

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: text !== ""
          text: bar.activeWindow ? (bar.activeWindow.app_id || "").toUpperCase() : ""
          color: Theme.secondary
          font.family: Theme.fontMono
          font.pixelSize: 10
          font.weight: Font.Bold
        }

        DecodeText {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, titleBox.width - 80)
          source: bar.activeWindow ? (bar.activeWindow.title || "") : "NO ACTIVE PROCESS"
          color: bar.activeWindow ? Theme.fg : Theme.muted
          elide: Text.ElideRight
          font.family: Theme.fontUi
          font.pixelSize: 15
          font.weight: Font.DemiBold
        }
      }

      GlitchText {
        anchors.verticalCenter: parent.verticalCenter
        visible: Blackwall.speaking
        text: Blackwall.current
        color: Theme.danger
        font.family: Theme.fontUi
        font.pixelSize: 15
        font.weight: Font.Bold
        font.letterSpacing: 2
        minGap: 300
        maxGap: 700
      }
    }
  }

  // ------------------------------------------------------------ centre

  Item {
    id: centre
    anchors.horizontalCenter: frame.horizontalCenter
    anchors.verticalCenter: frame.verticalCenter
    width: clockRow.width + 24
    height: 28

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    Plate {
      anchors.fill: parent
      cut: 8
      cutBL: 8
      fill: centreArea.containsMouse || Hud.ccOpen ? Theme.alpha(Theme.warn, 0.12) : "transparent"
      stroke: Theme.alpha(Theme.warn, centreArea.containsMouse || Hud.ccOpen ? 0.6 : 0.25)
    }

    Row {
      id: clockRow
      anchors.centerIn: parent
      spacing: 10

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.warn
        font.family: Theme.fontUi
        font.pixelSize: 21
        font.weight: Font.Bold
        font.letterSpacing: 1
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: Qt.formatDateTime(clock.date, "ddd dd MMM").toUpperCase()
          color: Theme.fg
          font.family: Theme.fontUi
          font.pixelSize: 11
          font.weight: Font.Bold
          font.letterSpacing: 1
        }

        Text {
          text: "WK " + Qt.formatDateTime(clock.date, "yyyy") + " // " + (Weather.ready ? Weather.temp + "°C" : "--")
          color: Theme.subtle
          font.family: Theme.fontMono
          font.pixelSize: 8
        }
      }

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Weather.ready
        width: 16
        height: 16
        name: Weather.icon
        color: Theme.subtle
        weight: 1.6
      }
    }

    Hover {
      id: centreArea
      anchors.fill: parent
      onClicked: Hud.toggleCc(bar.output)
    }
  }

  // ------------------------------------------------------------ right

  Row {
    id: rightGroup
    anchors.right: frame.right
    anchors.rightMargin: 4
    anchors.verticalCenter: frame.verticalCenter
    spacing: 4

    Button {
      tone: Theme.warn
      onClicked: Hud.openBreach(bar.output)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "€$ " + Stats.format(Stats.eddies)
        color: Theme.warn
        font.family: Theme.fontUi
        font.pixelSize: 14
        font.weight: Font.Bold
      }
    }

    Button {
      tone: Theme.primary
      onClicked: Hud.openBreach(bar.output)

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        name: "matrix"
        color: Theme.primary
        weight: 1.6
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "BREACH"
        color: Theme.primary
        font.family: Theme.fontUi
        font.pixelSize: 13
        font.weight: Font.Bold
        font.letterSpacing: 1
      }
    }

    // OS selector
    Item {
      id: osChip
      anchors.verticalCenter: parent.verticalCenter
      width: osRow.width + 18
      height: 24

      Plate {
        anchors.fill: parent
        cut: 7
        fill: osArea.containsMouse || Hud.osOpen ? Theme.alpha(Theme.secondary, 0.18) : Theme.alpha(Theme.secondary, 0.06)
        stroke: Theme.secondary
        Behavior on fill { ColorAnimation { duration: 120 } }
      }

      Row {
        id: osRow
        anchors.centerIn: parent
        spacing: 6

        OsBadge {
          anchors.verticalCenter: parent.verticalCenter
          width: Theme.osInfo.logo === "zetatech" ? 46 : 22
          height: 16
          color: Theme.secondary
          weight: 4
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Theme.osInfo.short || Theme.os.toUpperCase()
          color: Theme.secondary
          font.family: Theme.fontUi
          font.pixelSize: 13
          font.weight: Font.Bold
          font.letterSpacing: 1
        }

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          width: 10
          height: 10
          name: Hud.osOpen ? "up" : "down"
          color: Theme.secondary
          weight: 2.4
        }
      }

      Hover {
        id: osArea
        anchors.fill: parent
        onClicked: Hud.toggleOs(bar.output)
      }
    }

    // wallpaper bank
    Button {
      tone: Hud.wallOpen ? Theme.secondary : Theme.primary
      onClicked: Hud.toggleWall(bar.output)

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        name: "image"
        color: Hud.wallOpen ? Theme.secondary : Theme.fg
        weight: 1.6
      }
    }

    Sep { anchors.verticalCenter: parent.verticalCenter }

    // system tray
    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Repeater {
        model: SystemTray.items.values
        delegate: Item {
          id: trayItem
          required property var modelData
          width: 24
          height: 24

          Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.primary, trayArea.containsMouse ? 0.14 : 0)
          }

          HoloIcon {
            anchors.centerIn: parent
            width: 16
            height: 16
            source: trayItem.modelData.icon
            glyph: (trayItem.modelData.title || "?").slice(0, 1).toUpperCase()
            tone: trayArea.containsMouse ? Theme.primary : Theme.fg
            glyphSize: 12
          }

          Hover {
            id: trayArea
            anchors.fill: parent
            onClicked: (mouse) => {
              const item = trayItem.modelData
              if (mouse.button === Qt.MiddleButton) item.secondaryActivate()
              else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                if (item.hasMenu) bar.trayMenuRequested(item, trayItem.mapToItem(bar, 0, 0).x)
              } else item.activate()
            }
            onWheel: (wheel) => trayItem.modelData.scroll(wheel.angleDelta.y / 120, false)
          }
        }
      }
    }

    Sep { anchors.verticalCenter: parent.verticalCenter }

    Button {
      tone: Audio.muted ? Theme.danger : Theme.primary
      onClicked: (mouse) => mouse.button === Qt.RightButton ? Hud.toggleCc(bar.output) : Audio.toggleMute()
      onWheel: (wheel) => Audio.nudge(wheel.angleDelta.y > 0 ? 0.05 : -0.05)

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        name: Audio.icon
        color: Audio.muted ? Theme.danger : Theme.fg
        weight: 1.7
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.muted ? "MUTE" : Math.round(Audio.volume * 100)
        color: Audio.muted ? Theme.danger : Theme.fg
        font.family: Theme.fontUi
        font.pixelSize: 14
        font.weight: Font.Bold
      }
    }

    Button {
      tone: Network.kind === "offline" ? Theme.danger : Theme.primary
      onClicked: Quickshell.execDetached([Theme.bin("kitty"), "--class", "cyberdeck-float", "-e", "nmtui"])

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        name: Network.icon
        color: Network.kind === "offline" ? Theme.danger : Theme.fg
        weight: 1.6
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Network.label
        color: Network.kind === "offline" ? Theme.danger : Theme.fg
        font.family: Theme.fontUi
        font.pixelSize: 13
        font.weight: Font.Bold
      }
    }

    Button {
      tone: Theme.tertiary
      onClicked: (mouse) => mouse.button === Qt.RightButton ? Hud.dnd = !Hud.dnd : Hud.toggleCc(bar.output)

      Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16

        Icon {
          anchors.fill: parent
          name: Hud.dnd ? "bell-off" : "bell"
          color: Notifs.count > 0 ? Theme.tertiary : Theme.fg
          weight: 1.7
        }

        Rectangle {
          visible: Notifs.count > 0 && !Hud.dnd
          x: 10
          y: -3
          width: Math.max(12, badge.implicitWidth + 4)
          height: 12
          color: Theme.tertiary

          Text {
            id: badge
            anchors.centerIn: parent
            text: Notifs.count > 9 ? "9+" : Notifs.count
            color: Theme.bg
            font.family: Theme.fontUi
            font.pixelSize: 10
            font.weight: Font.Bold
          }
        }
      }
    }

    // control center toggle
    Item {
      anchors.verticalCenter: parent.verticalCenter
      width: 36
      height: 24

      Plate {
        anchors.fill: parent
        cut: 0
        cutTL: 7
        fill: ccArea.containsMouse || Hud.ccOpen ? Theme.mix(Theme.secondary, Theme.white, 0.2) : Theme.secondary
        strokeW: 0
        Behavior on fill { ColorAnimation { duration: 120 } }
      }

      Icon {
        anchors.centerIn: parent
        width: 15
        height: 15
        name: Hud.ccOpen ? "close" : "menu"
        color: Theme.bg
        weight: 2.2
      }

      Hover {
        id: ccArea
        anchors.fill: parent
        onClicked: Hud.toggleCc(bar.output)
      }
    }
  }
}
