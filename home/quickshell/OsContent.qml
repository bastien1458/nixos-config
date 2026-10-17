import QtQuick
import Quickshell

// OS selector: every colour algorithm as a piece of cyberware.
Item {
  id: menu

  property real reveal: 1
  property string flash: ""

  implicitWidth: 620
  implicitHeight: column.height

  Connections {
    target: Theme
    function onDenied(id) {
      if (Theme.pendingKind === "wallpaper") return
      menu.flash = id
      deniedTimer.restart()
    }
  }

  Timer {
    id: deniedTimer
    interval: 2400
    onTriggered: menu.flash = ""
  }

  Column {
    id: column
    width: menu.width
    spacing: 6

    Item {
      width: parent.width
      height: 58
      opacity: Math.min(1, menu.reveal * 2)

      Plate {
        anchors.fill: parent
        cut: 14
        fill: Theme.alpha(Theme.bg, 0.95)
        stroke: Theme.secondary
        strokeW: 1.5
      }

      Column {
        x: 16
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: "OPERATING SYSTEM // CYBERWARE SLOT"
          color: Theme.secondary
          font.family: Theme.fontUi
          font.pixelSize: 19
          font.weight: Font.Bold
          font.letterSpacing: 2
        }

        MicroText {
          text: "EACH OS IS A COLOUR PICKING ALGORITHM RUN ON " + Theme.wallpaper.split("/").pop().toUpperCase() + " // SWAP IS LIVE"
          color: Theme.subtle
        }
      }

      Chip {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        label: Theme.switching ? "INSTALLING" : "SLOT 01 // ACTIVE"
        tone: Theme.switching ? Theme.warn : Theme.secondary
        flashing: Theme.switching
      }
    }

    Repeater {
      model: Theme.catalog
      delegate: Item {
        id: card
        required property var modelData
        required property int index
        readonly property bool current: modelData.id === Theme.os
        readonly property bool locked: modelData.hidden === true && !Stats.blackwall
        readonly property bool pending: Theme.switching && Theme.pendingOs === modelData.id
        readonly property bool rejected: menu.flash === modelData.id
        readonly property color tone: locked ? Theme.danger : Theme.roleOf(modelData, "primary")
        readonly property real local: Math.max(0, Math.min(1, menu.reveal * 1.8 - index * 0.1))
        width: column.width
        height: 96
        opacity: local
        transform: Translate { x: (1 - card.local) * 30 }

        Plate {
          anchors.fill: parent
          cut: 14
          cutBL: 8
          fill: card.current ? Theme.alpha(Theme.mix(Theme.bg, card.tone, 0.1), 0.97) : Theme.alpha(Theme.bg, cardArea.containsMouse ? 0.97 : 0.92)
          stroke: card.current || cardArea.containsMouse ? card.tone : Theme.alpha(card.tone, 0.35)
          strokeW: card.current ? 1.5 : 1
          Behavior on stroke { ColorAnimation { duration: 140 } }
        }

        Rectangle {
          x: 0
          y: 14
          width: 3
          height: parent.height - 28
          color: card.tone
          opacity: card.current ? 1 : 0.5
        }

        // the cyberware itself
        Item {
          x: 14
          anchors.verticalCenter: parent.verticalCenter
          width: 70
          height: 70

          Rectangle {
            anchors.fill: parent
            color: Theme.alpha(card.tone, 0.07)
            border.color: Theme.alpha(card.tone, 0.3)
            border.width: 1
          }

          OsBadge {
            anchors.centerIn: parent
            width: 58
            height: 50
            osId: card.modelData.id
            logo: card.modelData.logo || ""
            color: card.tone
            weight: 2.6
            opacity: card.locked ? 0.5 : 1
          }

          Brackets {
            anchors.fill: parent
            anchors.margins: -3
            len: 8
            tone: card.tone
            visible: card.current || cardArea.containsMouse
          }
        }

        Column {
          x: 100
          y: 12
          width: parent.width - 100 - 150
          spacing: 3

          GlitchText {
            width: parent.width
            text: card.locked ? "█████████" : card.modelData.name
            color: card.locked ? Theme.danger : Theme.fg
            elide: Text.ElideRight
            font.family: Theme.fontUi
            font.pixelSize: 19
            font.weight: Font.Bold
            font.letterSpacing: 1
            active: card.locked || card.rejected
            minGap: 900
            maxGap: 3000
          }

          Row {
            spacing: 5

            Chip { label: card.modelData["class"]; tone: card.tone; size: 10 }
            Chip { label: card.modelData.tier; tone: card.modelData.tier === "LEGENDARY" ? Theme.warn : (card.modelData.tier === "ICONIC" ? Theme.danger : Theme.tertiary); size: 10 }
            Chip { label: card.modelData.tagline; tone: Theme.subtle; size: 10 }
          }

          Text {
            width: parent.width
            text: card.rejected ? (Theme.lastError !== "" ? Theme.lastError : "ACCESS DENIED. THE WALL DOES NOT OPEN FOR YOU. YET.")
                : card.locked ? "Signature redacted by NetWatch. Something waits behind the code matrix."
                : card.modelData.desc
            color: card.rejected ? Theme.danger : Theme.subtle
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.family: Theme.fontUi
            font.pixelSize: 13
            font.weight: Font.Medium
          }
        }

        // maker and palette preview
        Column {
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Text {
            anchors.right: parent.right
            text: card.locked ? "\u2593\u2592\u2591 ???" : card.modelData.maker
            color: card.tone
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 2
          }

          Row {
            anchors.right: parent.right
            spacing: 2

            Repeater {
              model: ["bg", "surface", "primary", "secondary", "tertiary", "warn", "danger"]
              delegate: Rectangle {
                required property string modelData
                width: 15
                height: 15
                color: card.locked ? Theme.alpha(Theme.danger, 0.15 + Math.random() * 0.3) : Theme.roleOf(card.modelData, modelData)
                border.color: Theme.alpha(Theme.fg, 0.15)
                border.width: 1
              }
            }
          }

          Chip {
            anchors.right: parent.right
            label: card.current ? "INSTALLED" : card.pending ? "INSTALLING..." : card.locked ? "LOCKED" : "INSTALL"
            tone: card.current ? Theme.ok : card.locked ? Theme.danger : card.tone
            solid: card.current
            flashing: card.pending
            size: 10
          }
        }

        Clickable {
          id: cardArea
          anchors.fill: parent
          cursorShape: card.current ? Qt.ArrowCursor : Qt.PointingHandCursor
          onClicked: Theme.switchTo(card.modelData.id)
        }
      }
    }

    // bake the current OS into Stylix for every other app
    Item {
      width: parent.width
      height: 46
      opacity: Math.min(1, menu.reveal * 1.5)

      Plate {
        anchors.fill: parent
        cut: 12
        fill: engraveArea.containsMouse ? Theme.alpha(Theme.warn, 0.16) : Theme.alpha(Theme.bg, 0.92)
        stroke: Theme.alpha(Theme.warn, 0.6)
      }

      Row {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Icon { anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; name: "bolt"; color: Theme.warn }

        Column {
          anchors.verticalCenter: parent.verticalCenter

          Text {
            text: "ENGRAVE INTO SYSTEM FIRMWARE"
            color: Theme.warn
            font.family: Theme.fontUi
            font.pixelSize: 15
            font.weight: Font.Bold
            font.letterSpacing: 1.5
          }

          MicroText {
            text: "LIVE: SHELL, KITTY, NIRI, GTK ON LAUNCH // ENGRAVE: NIXOS-REBUILD OF " + Settings.rebuildRepo.toUpperCase() + " WITH STYLIX"
            color: Theme.subtle
          }
        }
      }

      Clickable {
        id: engraveArea
        anchors.fill: parent
        onClicked: {
          Hud.closeAll()
          Quickshell.execDetached([Theme.bin("kitty"), "--class", "cyberdeck-float", "--title", "ENGRAVING FIRMWARE", "-e", Theme.bin("engrave")])
        }
      }
    }
  }
}
