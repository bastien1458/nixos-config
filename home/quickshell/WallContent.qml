import QtQuick
import Quickshell

// Wallpaper bank: a card per image of home/assets/wallpapers, with the palette
// the active OS pulls out of it. Picking one recolours the whole deck.
FocusScope {
  id: bank

  property real reveal: 1
  property real maxHeight: 900
  property int selected: 0
  property string flash: ""

  readonly property var list: Theme.wallpapers
  readonly property int columns: width > 900 ? 3 : 2
  readonly property real cardW: (width - (columns - 1) * 8) / columns
  readonly property real cardH: Math.round(cardW * 9 / 16) + 62

  signal closeRequested()

  implicitHeight: column.height

  function apply(index) {
    const w = list[index]
    if (!w || w.current) return
    Theme.setWallpaper(w.path)
  }

  function move(delta) {
    if (list.length === 0) return
    selected = Math.max(0, Math.min(list.length - 1, selected + delta))
    Sounds.play("hover")
    const row = Math.floor(selected / columns)
    const top = row * (cardH + 8)
    if (top < flick.contentY) flick.contentY = top
    else if (top + cardH > flick.contentY + flick.height) flick.contentY = top + cardH - flick.height
  }

  onListChanged: {
    const current = list.findIndex(w => w.current)
    if (current >= 0) selected = current
  }

  Keys.onPressed: (event) => {
    if (event.key === Qt.Key_Left) move(-1)
    else if (event.key === Qt.Key_Right) move(1)
    else if (event.key === Qt.Key_Up) move(-columns)
    else if (event.key === Qt.Key_Down) move(columns)
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      Sounds.play("click")
      apply(selected)
    } else return
    event.accepted = true
  }

  Connections {
    target: Theme
    function onDenied(id) {
      if (Theme.pendingKind !== "wallpaper") return
      bank.flash = Theme.lastError
      deniedTimer.restart()
    }
  }

  Timer {
    id: deniedTimer
    interval: 4000
    onTriggered: bank.flash = ""
  }

  Column {
    id: column
    width: bank.width
    spacing: 6

    Item {
      width: parent.width
      height: 58
      opacity: Math.min(1, bank.reveal * 2)

      Plate {
        anchors.fill: parent
        cut: 14
        fill: Theme.alpha(Theme.bg, 0.95)
        stroke: Theme.primary
        strokeW: 1.5
      }

      Column {
        x: 16
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: "OPTICS // WALLPAPER BANK"
          color: Theme.primary
          font.family: Theme.fontUi
          font.pixelSize: 19
          font.weight: Font.Bold
          font.letterSpacing: 2
        }

        MicroText {
          text: bank.flash !== "" ? bank.flash
              : bank.list.length + " IMAGES IN " + (Theme.config.wallpaperDir || "HOME/ASSETS/WALLPAPERS").toUpperCase() + " // RECOLOURED BY " + (Theme.osInfo.short || Theme.os.toUpperCase())
          color: bank.flash !== "" ? Theme.danger : Theme.subtle
        }
      }

      Chip {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        readonly property bool busy: Theme.switching && Theme.pendingKind === "wallpaper"
        label: busy ? "RECALIBRATING" : "SUPER+W"
        tone: busy ? Theme.warn : Theme.primary
        flashing: busy
      }
    }

    Item {
      width: parent.width
      height: bank.list.length > 0 ? flick.height : 80
      opacity: Math.min(1, bank.reveal * 1.6)

      Text {
        visible: bank.list.length === 0
        anchors.centerIn: parent
        text: "SCANNING WALLPAPER BANK..."
        color: Theme.subtle
        font.family: Theme.fontUi
        font.pixelSize: 18
        font.weight: Font.Bold
        font.letterSpacing: 2
      }

      Flickable {
        id: flick
        width: parent.width
        height: Math.min(grid.height, bank.maxHeight - 58 - 46 - 12)
        contentHeight: grid.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Grid {
          id: grid
          width: flick.width
          columns: bank.columns
          spacing: 8

          Repeater {
            model: bank.list
            delegate: Item {
              id: card
              required property var modelData
              required property int index
              readonly property bool current: modelData.current === true
              readonly property bool picked: index === bank.selected
              readonly property bool pending: Theme.switching && Theme.pendingKind === "wallpaper" && bank.selected === index
              readonly property color tone: modelData.roles && modelData.roles.primary ? modelData.roles.primary : Theme.primary
              readonly property real local: Math.max(0, Math.min(1, bank.reveal * 1.8 - index * 0.08))
              width: bank.cardW
              height: bank.cardH
              opacity: local
              transform: Translate { y: (1 - card.local) * 20 }

              Plate {
                anchors.fill: parent
                cut: 14
                cutBL: 8
                fill: card.current ? Theme.alpha(Theme.mix(Theme.bg, card.tone, 0.1), 0.97) : Theme.alpha(Theme.bg, 0.94)
                stroke: card.current || card.picked || area.containsMouse ? card.tone : Theme.alpha(card.tone, 0.35)
                strokeW: card.current ? 1.5 : 1
                Behavior on stroke { ColorAnimation { duration: 140 } }
              }

              Item {
                id: thumb
                x: 6
                y: 6
                width: parent.width - 12
                height: Math.round(width * 9 / 16)
                clip: true

                Rectangle { anchors.fill: parent; color: Theme.alpha(card.tone, 0.08) }

                Image {
                  anchors.fill: parent
                  source: "file://" + card.modelData.path
                  sourceSize: Qt.size(480, 270)
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  smooth: true
                  opacity: status === Image.Ready ? (card.current || card.picked || area.containsMouse ? 1 : 0.72) : 0
                  Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                // scanlines over the preview, like an optics feed
                Column {
                  anchors.fill: parent
                  spacing: 2
                  Repeater {
                    model: Math.ceil(thumb.height / 3)
                    delegate: Rectangle { width: thumb.width; height: 1; color: "#000000"; opacity: 0.18 }
                  }
                }

                Brackets {
                  anchors.fill: parent
                  anchors.margins: 6
                  len: 14
                  tone: card.tone
                  visible: card.current || card.picked || area.containsMouse
                }

                Chip {
                  x: 8
                  y: 8
                  visible: card.current || card.pending || card.modelData.engraved === false
                  label: card.current ? "ACTIVE" : card.pending ? "RECALIBRATING..." : "NEW // NOT ENGRAVED"
                  tone: card.current ? Theme.ok : card.pending ? Theme.warn : Theme.tertiary
                  solid: card.current
                  flashing: card.pending
                  size: 10
                }
              }

              Text {
                x: 14
                y: thumb.y + thumb.height + 10
                width: parent.width - 28 - swatches.width
                text: card.modelData.name.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ").toUpperCase()
                color: card.current ? card.tone : Theme.fg
                elide: Text.ElideRight
                font.family: Theme.fontUi
                font.pixelSize: 17
                font.weight: Font.Bold
                font.letterSpacing: 1
              }

              MicroText {
                x: 14
                y: thumb.y + thumb.height + 34
                text: card.modelData.name.toUpperCase()
              }

              // the palette the active OS pulls out of this image
              Row {
                id: swatches
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: thumb.y + thumb.height + 14
                spacing: 2

                Repeater {
                  model: ["bg", "surface", "primary", "secondary", "tertiary", "warn", "danger"]
                  delegate: Rectangle {
                    required property string modelData
                    width: 14
                    height: 14
                    color: card.modelData.roles && card.modelData.roles[modelData] ? card.modelData.roles[modelData] : "transparent"
                    border.color: Theme.alpha(Theme.fg, 0.15)
                    border.width: 1
                  }
                }
              }

              Clickable {
                id: area
                anchors.fill: parent
                cursorShape: card.current ? Qt.ArrowCursor : Qt.PointingHandCursor
                onEntered: bank.selected = card.index
                onClicked: bank.apply(card.index)
              }
            }
          }
        }
      }
    }

    Item {
      width: parent.width
      height: 46
      opacity: Math.min(1, bank.reveal * 1.5)

      Plate {
        anchors.fill: parent
        cut: 12
        fill: Theme.alpha(Theme.bg, 0.92)
        stroke: Theme.alpha(Theme.warn, 0.6)
      }

      Row {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Icon { anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; name: "image"; color: Theme.warn }

        Column {
          anchors.verticalCenter: parent.verticalCenter

          Text {
            text: "DROP IMAGES IN THE WALLPAPER FOLDER OF THE REPO"
            color: Theme.warn
            font.family: Theme.fontUi
            font.pixelSize: 15
            font.weight: Font.Bold
            font.letterSpacing: 1.5
          }

          MicroText {
            text: "LIVE: SHELL, KITTY, NIRI, GTK ON LAUNCH // ENGRAVE (OS MENU): BAKES THE WALLPAPER INTO STYLIX, GREETER AND CURSOR"
            color: Theme.subtle
          }
        }
      }

      Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        KeyCap { label: "↵"; tone: Theme.subtle }
        KeyCap { label: "ESC"; tone: Theme.subtle }
      }
    }
  }
}
