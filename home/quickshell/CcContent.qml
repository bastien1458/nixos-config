import QtQuick
import QtQuick.Effects
import Quickshell

// The control center panel: media, audio, weather, calendar, deck status
// and the notification log, in the style of the in-game inventory screens.
Item {
  id: cc

  property real reveal: 1

  implicitWidth: 470
  implicitHeight: column.height

  component Section: Item {
    id: section
    property string title: ""
    property string icon: ""
    property string index: ""
    property color tone: Theme.primary
    default property alias content: body.data
    property real order: 0
    readonly property real local: Math.max(0, Math.min(1, cc.reveal * 1.6 - order * 0.12))
    width: cc.width
    height: body.childrenRect.height + 48
    opacity: local
    transform: Translate { x: (1 - section.local) * 24 }

    Plate {
      anchors.fill: parent
      cut: 12
      cutBL: 6
      fill: Settings.plate
      stroke: Theme.frameDim
    }

    Header {
      x: 1
      y: 1
      width: parent.width - 2
      height: 24
      label: section.title
      icon: section.icon
      index: section.index
      tone: section.tone
      solid: false
    }

    Item {
      id: body
      x: 14
      y: 36
      width: parent.width - 28
    }
  }

  component Value: Text {
    color: Theme.fg
    font.family: Theme.fontUi
    font.pixelSize: 14
    font.weight: Font.Bold
  }

  component Caption: Text {
    color: Theme.subtle
    font.family: Theme.fontMono
    font.pixelSize: 9
    font.letterSpacing: 0.5
  }

  Column {
    id: column
    width: cc.width
    spacing: 8

    // ---------------------------------------------- identity

    Item {
      width: cc.width
      height: 74
      opacity: Math.min(1, cc.reveal * 1.6)

      Plate {
        anchors.fill: parent
        cut: 16
        fill: Settings.plate
        stroke: Theme.primary
        strokeW: 1.5
      }

      Rectangle { x: 0; y: 14; width: 3; height: parent.height - 28; color: Theme.primary }

      OsBadge {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 50
        height: 40
        color: Theme.primary
      }

      Column {
        x: 72
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        DecodeText {
          source: "NETRUNNER // " + (Quickshell.env("USER") || "V").toUpperCase()
          color: Theme.fg
          font.family: Theme.fontUi
          font.pixelSize: 20
          font.weight: Font.Bold
          font.letterSpacing: 1.5
        }

        Text {
          text: (Theme.osInfo.name || "") + "  //  UPTIME " + Sys.uptime
          color: Theme.primary
          font.family: Theme.fontUi
          font.pixelSize: 13
          font.weight: Font.DemiBold
          font.letterSpacing: 0.5
        }

        Caption {
          text: "BLACKWALL INTEGRITY " + Blackwall.integrity.toFixed(2) + "%  //  KERNEL " + Sys.kernel
          color: Blackwall.integrity < 99 ? Theme.danger : Theme.subtle
        }
      }

      Chip {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 12
        label: Theme.osInfo.tier || ""
        tone: Theme.osInfo.tier === "LEGENDARY" ? Theme.warn : Theme.tertiary
        size: 10
      }
    }

    // ---------------------------------------------- quick toggles

    Row {
      width: cc.width
      spacing: 6
      opacity: Math.min(1, cc.reveal * 1.6)

      Tile {
        width: (cc.width - 30) / 6
        icon: Hud.dnd ? "bell-off" : "bell"
        label: "CAMO"
        hint: Hud.dnd ? "SILENT" : "VISIBLE"
        active: Hud.dnd
        tone: Theme.tertiary
        onClicked: Hud.dnd = !Hud.dnd
      }

      Tile {
        width: (cc.width - 30) / 6
        icon: Hud.caffeine ? "eye" : "eye-off"
        label: "ADRENALINE"
        hint: Hud.caffeine ? "NO SLEEP" : "IDLE OK"
        active: Hud.caffeine
        tone: Theme.warn
        onClicked: Hud.caffeine = !Hud.caffeine
      }

      Tile {
        width: (cc.width - 30) / 6
        icon: "matrix"
        label: "BREACH"
        hint: Stats.breaches + " RUNS"
        onClicked: Hud.openBreach(Hud.ccOutput)
      }

      Tile {
        width: (cc.width - 30) / 6
        icon: "hack"
        label: "QUICKHACK"
        hint: "SUPER+D"
        onClicked: {
          Hud.closeAll()
          Hud.quickhackRequested()
        }
      }

      Tile {
        width: (cc.width - 30) / 6
        icon: Sounds.fx ? (Sounds.ambience ? "volume" : "volume-low") : "volume-mute"
        label: "SOUND"
        hint: Sounds.fx ? (Sounds.ambience ? "ALL" : "FX ONLY") : "MUTED"
        active: Sounds.fx
        tone: Theme.secondary
        onClicked: Sounds.cycle()
      }

      Tile {
        width: (cc.width - 30) / 6
        icon: "lock"
        label: "LOCK"
        hint: "SUPER+ALT+L"
        tone: Theme.danger
        onClicked: {
          Hud.closeAll()
          Lock.lock()
        }
      }
    }

    // ---------------------------------------------- media

    Section {
      title: "BRAINDANCE // MEDIA"
      icon: "music"
      index: Media.active ? (Media.player.identity || "MPRIS").toUpperCase() : "NO PLAYER"
      order: 1

      Item {
        width: parent.width
        height: 104

        Item {
          id: art
          width: 104
          height: 104

          Rectangle {
            anchors.fill: parent
            color: Theme.primaryDeep
            border.color: Theme.frame
            border.width: 1
          }

          Image {
            id: cover
            anchors.fill: parent
            anchors.margins: 1
            source: Media.art
            sourceSize: Qt.size(208, 208)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
          }

          MultiEffect {
            anchors.fill: cover
            source: cover
            visible: cover.status === Image.Ready
            colorization: 0.55
            colorizationColor: Theme.primary
            contrast: 0.15
          }

          Icon {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            width: 40
            height: 40
            name: "music"
            color: Theme.frame
          }

          Column {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 2
            visible: cover.status === Image.Ready
            Repeater {
              model: 34
              delegate: Rectangle { width: art.width - 2; height: 1; color: "#000000"; opacity: 0.22 }
            }
          }

          Brackets { anchors.fill: parent; anchors.margins: -4; len: 10; tone: Theme.primary }
        }

        Column {
          x: 120
          width: parent.width - 120
          spacing: 2

          DecodeText {
            width: parent.width
            source: Media.title.toUpperCase()
            color: Theme.fg
            elide: Text.ElideRight
            font.family: Theme.fontUi
            font.pixelSize: 19
            font.weight: Font.Bold
          }

          Text {
            width: parent.width
            text: Media.artist.toUpperCase()
            color: Theme.secondary
            elide: Text.ElideRight
            font.family: Theme.fontUi
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: 1
          }

          Item { width: 1; height: 10 }

          Rectangle {
            width: parent.width
            height: 4
            color: Theme.primaryDeep

            Rectangle {
              width: Media.length > 0 ? parent.width * Math.min(1, Media.position / Media.length) : 0
              height: parent.height
              color: Theme.primary
              Behavior on width { NumberAnimation { duration: 900 } }
            }
          }

          Item {
            width: parent.width
            height: 14

            Caption { text: Media.format(Media.position) }
            Caption { anchors.right: parent.right; text: Media.length > 0 ? Media.format(Media.length) : "--:--" }
          }

          Row {
            spacing: 10

            Repeater {
              model: [
                { icon: "prev", act: "previous", big: false },
                { icon: Media.playing ? "pause" : "play", act: "toggle", big: true },
                { icon: "next", act: "next", big: false },
                { icon: "refresh", act: "cycle", big: false }
              ]
              delegate: Item {
                id: control
                required property var modelData
                width: modelData.big ? 40 : 30
                height: 30

                Plate {
                  anchors.fill: parent
                  cut: 6
                  fill: control.modelData.big ? Theme.primary : Theme.alpha(Theme.primary, controlArea.containsMouse ? 0.18 : 0.06)
                  stroke: Theme.alpha(Theme.primary, 0.6)
                }

                Icon {
                  anchors.centerIn: parent
                  width: control.modelData.big ? 18 : 14
                  height: width
                  name: control.modelData.icon
                  color: control.modelData.big ? Theme.bg : Theme.primary
                }

                Clickable {
                  id: controlArea
                  anchors.fill: parent
                  enabled: Media.active
                  onClicked: {
                    const p = Media.player
                    if (control.modelData.act === "toggle") p.togglePlaying()
                    else if (control.modelData.act === "next") p.next()
                    else if (control.modelData.act === "previous") p.previous()
                    else Media.cycle()
                  }
                }
              }
            }
          }
        }
      }
    }

    // ---------------------------------------------- audio

    Section {
      title: "AUDIO // SONIC MATRIX"
      icon: Audio.icon
      index: Math.round(Audio.volume * 100) + "%"
      order: 2

      Column {
        width: parent.width
        spacing: 9

        Repeater {
          model: [
            { kind: "out", name: Audio.nameOf(Audio.sink), icon: Audio.icon, value: Audio.volume, muted: Audio.muted },
            { kind: "in", name: Audio.nameOf(Audio.source), icon: Audio.micMuted ? "mic-off" : "mic", value: Audio.micVolume, muted: Audio.micMuted }
          ]
          delegate: Item {
            id: channel
            required property var modelData
            width: parent.width
            height: 34

            Item {
              width: 22
              height: 22
              y: 6

              Icon {
                anchors.fill: parent
                name: channel.modelData.icon
                color: channel.modelData.muted ? Theme.danger : Theme.primary
              }

              Clickable {
                anchors.fill: parent
                onClicked: channel.modelData.kind === "out" ? Audio.toggleMute() : Audio.toggleMic()
              }
            }

            Caption {
              x: 34
              text: (channel.modelData.kind === "out" ? "OUTPUT // " : "INPUT // ") + channel.modelData.name
              width: parent.width - 34 - 40
              elide: Text.ElideRight
            }

            Value {
              anchors.right: parent.right
              text: channel.modelData.muted ? "MUTE" : Math.round(channel.modelData.value * 100)
              color: channel.modelData.muted ? Theme.danger : Theme.fg
            }

            Slider {
              x: 34
              y: 18
              width: parent.width - 34
              height: 12
              value: channel.modelData.value
              muted: channel.modelData.muted
              tone: channel.modelData.kind === "out" ? Theme.primary : Theme.secondary
              onMoved: (v) => channel.modelData.kind === "out" ? Audio.setVolume(v) : Audio.setMic(v)
            }
          }
        }

        Repeater {
          model: Audio.streams.slice(0, 4)
          delegate: Item {
            id: stream
            required property var modelData
            width: parent.width
            height: 20

            Caption {
              width: 120
              anchors.verticalCenter: parent.verticalCenter
              text: Audio.nameOf(stream.modelData)
              elide: Text.ElideRight
              color: Theme.fg
            }

            Slider {
              x: 128
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 128 - 36
              height: 8
              segments: 32
              value: stream.modelData.audio ? stream.modelData.audio.volume : 0
              tone: Theme.tertiary
              onMoved: (v) => { if (stream.modelData.audio) stream.modelData.audio.volume = v }
            }

            Caption {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: stream.modelData.audio ? Math.round(stream.modelData.audio.volume * 100) : "--"
            }
          }
        }
      }
    }

    // ---------------------------------------------- weather + calendar

    Row {
      width: cc.width
      spacing: 8

      Section {
        width: (cc.width - 8) * 0.44
        title: "WEATHER"
        icon: Weather.icon
        index: Weather.place
        tone: Theme.secondary
        order: 3

        Column {
          width: parent.width
          spacing: 6

          Row {
            spacing: 10

            Icon {
              width: 44
              height: 44
              name: Weather.icon
              color: Theme.secondary
              weight: 1.4
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter

              Text {
                text: Weather.ready ? Weather.temp + "°" : "--"
                color: Theme.fg
                font.family: Theme.fontUi
                font.pixelSize: 34
                font.weight: Font.Bold
              }
            }
          }

          Text {
            text: Weather.ready ? Weather.condition : (Weather.failed ? "UPLINK LOST" : "SCANNING...")
            color: Weather.failed ? Theme.danger : Theme.secondary
            font.family: Theme.fontUi
            font.pixelSize: 14
            font.weight: Font.Bold
            font.letterSpacing: 1
          }

          Caption {
            text: "FEELS " + Weather.feels + "°  //  HUM " + Weather.humidity + "%\nWIND " + Weather.wind + " KM/H"
            lineHeight: 1.2
          }

          Row {
            spacing: 4
            Repeater {
              model: Weather.days
              delegate: Column {
                required property var modelData
                width: 40
                spacing: 1

                Caption {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd").toUpperCase()
                }

                Icon {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: 16
                  height: 16
                  name: modelData.icon
                  color: Theme.subtle
                  weight: 1.5
                }

                Caption {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.max + "/" + modelData.min
                  color: Theme.fg
                }
              }
            }
          }
        }
      }

      Section {
        width: (cc.width - 8) * 0.56
        title: "CALENDAR"
        icon: "calendar"
        index: Qt.formatDate(new Date(), "dd.MM")
        tone: Theme.primary
        order: 3.5

        Calendar {
          width: parent.width
        }
      }
    }

    // ---------------------------------------------- deck status

    Section {
      title: "CYBERDECK STATUS"
      icon: "chip"
      index: Stats.format(Stats.eddies) + " €$"
      order: 4

      Column {
        width: parent.width
        spacing: 8

        Repeater {
          model: [
            { label: "SYNAPSE LOAD", value: Sys.cpu, text: Math.round(Sys.cpu * 100) + "%", tone: Sys.cpu > 0.85 ? Theme.danger : Theme.primary },
            { label: "RAM", value: Sys.mem, text: Sys.memUsed.toFixed(1) + " / " + Sys.memTotal.toFixed(0) + " GB", tone: Sys.mem > 0.85 ? Theme.danger : Theme.secondary }
          ]
          delegate: Item {
            required property var modelData
            width: parent.width
            height: 26

            Caption { text: modelData.label }
            Caption { anchors.right: parent.right; text: modelData.text; color: Theme.fg }

            Slider {
              y: 14
              width: parent.width
              height: 9
              segments: 40
              value: modelData.value
              tone: modelData.tone
              enabled: false
            }
          }
        }
      }
    }

    // ---------------------------------------------- notifications

    Section {
      title: "MESSAGES"
      icon: Hud.dnd ? "bell-off" : "bell"
      index: Notifs.count + " UNREAD"
      tone: Theme.tertiary
      order: 5

      Item {
        width: parent.width
        height: Math.min(Math.max(30, log.contentHeight), 230) + 26

        ListView {
          id: log
          width: parent.width
          height: parent.height - 26
          clip: true
          spacing: 6
          model: Notifs.list.slice().reverse()
          boundsBehavior: Flickable.StopAtBounds

          delegate: Item {
            id: entry
            required property var modelData
            width: log.width
            height: Math.max(42, msg.implicitHeight + 24)
            readonly property bool critical: Notifs.isCritical(modelData)

            Rectangle {
              anchors.fill: parent
              color: Theme.alpha(entry.critical ? Theme.danger : Theme.tertiary, entryArea.containsMouse ? 0.12 : 0.05)
              border.color: Theme.alpha(entry.critical ? Theme.danger : Theme.tertiary, 0.3)
              border.width: 1
            }

            Rectangle { width: 2; height: parent.height; color: entry.critical ? Theme.danger : Theme.tertiary }

            Caption {
              x: 10
              y: 5
              text: (entry.modelData.appName || "UNKNOWN").toUpperCase()
              color: entry.critical ? Theme.danger : Theme.tertiary
            }

            Text {
              id: msg
              x: 10
              y: 17
              width: parent.width - 40
              text: "<b>" + entry.modelData.summary + "</b>" + (entry.modelData.body ? "  " + entry.modelData.body : "")
              textFormat: Text.StyledText
              color: Theme.fg
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
              font.family: Theme.fontUi
              font.pixelSize: 13
              font.weight: Font.Medium
            }

            Clickable {
              id: entryArea
              anchors.fill: parent
              onClicked: Notifs.dismiss(entry.modelData)
            }

            Icon {
              anchors.right: parent.right
              anchors.rightMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              width: 12
              height: 12
              name: "close"
              color: Theme.subtle
              visible: entryArea.containsMouse
            }
          }
        }

        Text {
          visible: Notifs.count === 0
          y: 4
          text: "NO INCOMING TRANSMISSIONS"
          color: Theme.muted
          font.family: Theme.fontUi
          font.pixelSize: 14
          font.weight: Font.Bold
          font.letterSpacing: 1.5
        }

        Row {
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          spacing: 6
          visible: Notifs.count > 0

          Icon { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; name: "trash"; color: Theme.subtle }

          Text {
            text: "PURGE ALL"
            color: clearArea.containsMouse ? Theme.danger : Theme.subtle
            font.family: Theme.fontUi
            font.pixelSize: 12
            font.weight: Font.Bold
            font.letterSpacing: 1

            Clickable {
              id: clearArea
              anchors.fill: parent
              anchors.margins: -4
              onClicked: Notifs.clear()
            }
          }
        }
      }
    }
  }
}
