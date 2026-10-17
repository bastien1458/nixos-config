import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// SHELL SETTINGS: everything of the deck that can change without a rebuild.
// Opened by the "Shell Settings" app of the launcher (see shell.nix) or
// `quickshell -c cyberdeck ipc call settings open`.
Overlay {
  id: window

  screen: Hud.screenNamed(Hud.settingsOutput)
  open: Hud.settingsOpen
  WlrLayershell.namespace: "cyberdeck-settings"
  blurItem: backdrop
  onDismissed: Hud.settingsOpen = false

  // ------------------------------------------------------------ pieces

  component Section: Item {
    id: section
    property string title: ""
    property string index: ""
    property string icon: ""
    property color tone: Theme.primary
    property real order: 0
    default property alias content: body.data
    readonly property real local: Math.max(0, Math.min(1, window.reveal * 1.6 - order * 0.12))

    width: parent ? parent.width : 0
    height: body.height + 48
    opacity: local
    transform: Translate { x: (1 - section.local) * 24 }

    Plate {
      anchors.fill: parent
      cut: 12
      cutBL: 6
      fill: Theme.alpha(Theme.bg, 0.93)
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

    Column {
      id: body
      x: 14
      y: 36
      width: parent.width - 28
      spacing: 10
    }
  }

  // a label on the left, its control on the right
  component Field: Item {
    id: field
    property string label: ""
    property string hint: ""
    default property alias control: slot.data

    width: parent ? parent.width : 0
    height: Math.max(28, slot.childrenRect.height)

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - slot.width - 12
      Text {
        text: field.label
        color: Theme.fg
        font.family: Theme.fontUi
        font.pixelSize: 14
        font.weight: Font.Bold
        font.letterSpacing: 0.5
      }
      Text {
        visible: field.hint !== ""
        width: parent.width
        text: field.hint
        color: Theme.subtle
        elide: Text.ElideRight
        font.family: Theme.fontMono
        font.pixelSize: 9
        font.letterSpacing: 0.5
      }
    }

    Item {
      id: slot
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: childrenRect.width
      height: childrenRect.height
    }
  }

  // a row of tags, the picked one filled
  component Choice: Row {
    id: choice
    property var options: []
    property var labels: []
    property var current
    property color tone: Theme.primary
    signal picked(var value)
    spacing: 6

    Repeater {
      model: choice.options
      delegate: Chip {
        required property var modelData
        required property int index
        label: choice.labels[index] || String(modelData).toUpperCase()
        tone: choice.tone
        solid: choice.current === modelData
        size: 11
        Clickable {
          anchors.fill: parent
          onClicked: choice.picked(parent.modelData)
        }
      }
    }
  }

  component Toggle: Choice {
    options: [true, false]
    labels: ["ON", "OFF"]
  }

  // a gauge with its value written next to it
  component Gauge: Row {
    id: gauge
    property real from: 0
    property real to: 1
    property real value: 0
    property int steps: 20
    property string text: ""
    property color tone: Theme.primary
    signal adjusted(real value)
    spacing: 10

    Slider {
      anchors.verticalCenter: parent.verticalCenter
      width: 180
      segments: gauge.steps
      tone: gauge.tone
      value: (gauge.value - gauge.from) / (gauge.to - gauge.from)
      onMoved: (v) => gauge.adjusted(gauge.from + Math.round(v * gauge.steps) / gauge.steps * (gauge.to - gauge.from))
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: 44
      text: gauge.text
      color: gauge.tone
      horizontalAlignment: Text.AlignRight
      font.family: Theme.fontMono
      font.pixelSize: 12
      font.weight: Font.Bold
    }
  }

  // free text, saved on Enter or when the field loses focus
  component Entry: Item {
    id: entry
    property string value: ""
    property string placeholder: ""
    property color tone: Theme.primary
    signal committed(string value)

    width: parent ? parent.width : 0
    height: 30

    Plate {
      anchors.fill: parent
      cut: 8
      fill: Theme.alpha(entry.tone, input.activeFocus ? 0.12 : 0.05)
      stroke: Theme.alpha(entry.tone, input.activeFocus ? 0.9 : 0.35)
    }

    Text {
      anchors.fill: input
      visible: input.text === ""
      text: entry.placeholder
      color: Theme.muted
      elide: Text.ElideMiddle
      verticalAlignment: Text.AlignVCenter
      font: input.font
    }

    TextInput {
      id: input
      x: 10
      width: parent.width - 20
      height: parent.height
      verticalAlignment: TextInput.AlignVCenter
      text: entry.value
      color: Theme.fg
      selectionColor: Theme.alpha(entry.tone, 0.5)
      selectByMouse: true
      clip: true
      font.family: Theme.fontMono
      font.pixelSize: 12
      onAccepted: focus = false
      onEditingFinished: if (text.trim() !== entry.value) entry.committed(text.trim())
      // the saved value comes back after an edit, or from the file
      Connections {
        target: entry
        function onValueChanged() { if (!input.activeFocus) input.text = entry.value }
      }
    }
  }

  component Action: Item {
    id: action
    property string label: ""
    property color tone: Theme.primary
    signal triggered()

    width: actionText.implicitWidth + 28
    height: 28

    Plate {
      anchors.fill: parent
      cut: 8
      fill: actionArea.containsMouse ? action.tone : Theme.alpha(action.tone, 0.1)
      stroke: action.tone
    }

    Text {
      id: actionText
      anchors.centerIn: parent
      text: action.label
      color: actionArea.containsMouse ? Theme.bg : action.tone
      font.family: Theme.fontUi
      font.pixelSize: 12
      font.weight: Font.Bold
      font.letterSpacing: 1
    }

    Clickable {
      id: actionArea
      anchors.fill: parent
      onClicked: action.triggered()
    }
  }

  // is there a flake to rebuild from in the chosen folder?
  property bool flakeFound: false

  Process {
    id: probe
    command: ["test", "-f", Settings.rebuildRepo + "/flake.nix"]
    onExited: (code) => window.flakeFound = code === 0
  }

  Connections {
    target: Settings
    function onRebuildRepoChanged() { probe.running = true }
  }

  onOpenChanged: if (open) probe.running = true

  // ------------------------------------------------------------ panel

  Item {
    id: panel
    anchors.horizontalCenter: parent.horizontalCenter
    y: Settings.barBottom ? parent.height - height - 6 + (1 - window.reveal) * 16 : 6 - (1 - window.reveal) * 16
    width: 600
    height: Math.min(column.height, parent.height - 16)
    opacity: Math.min(1, window.reveal * 2)

    Backdrop { id: backdrop }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Flickable {
      anchors.fill: parent
      contentHeight: column.height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height

      Column {
        id: column
        width: panel.width
        spacing: 8

        Header {
          width: parent.width
          height: 30
          label: "SHELL SETTINGS"
          index: "SYS.CFG"
          icon: "chip"
          opacity: Math.min(1, window.reveal * 1.6)
        }

        Section {
          title: "FIRMWARE SOURCE"
          index: "01"
          icon: "refresh"
          tone: Theme.warn
          order: 0

          Text {
            width: parent.width
            text: "The clone nixos-rebuild runs from: ENGRAVE, the OS selector and the wallpaper bank write back into it."
            wrapMode: Text.WordWrap
            color: Theme.subtle
            font.family: Theme.fontMono
            font.pixelSize: 10
          }

          Entry {
            value: Settings.repo
            placeholder: Settings.defaultRepo + "   (flake.nix default)"
            tone: Theme.warn
            onCommitted: (v) => Settings.set("repo", v)
          }

          Item {
            width: parent.width
            height: 28

            Chip {
              anchors.verticalCenter: parent.verticalCenter
              label: window.flakeFound ? "FLAKE FOUND" : "NO FLAKE.NIX HERE"
              tone: window.flakeFound ? Theme.primary : Theme.danger
              size: 11
            }

            Row {
              anchors.right: parent.right
              spacing: 8

              Action {
                visible: Settings.repo !== ""
                label: "DEFAULT"
                tone: Theme.subtle
                onTriggered: Settings.set("repo", "")
              }

              Action {
                label: "ENGRAVE NOW"
                tone: Theme.warn
                onTriggered: {
                  Hud.settingsOpen = false
                  Quickshell.execDetached([Theme.bin("kitty"), "--class", "cyberdeck-float", "--title", "ENGRAVING FIRMWARE", "-e", Theme.bin("engrave")])
                }
              }
            }
          }
        }

        Section {
          title: "BAR"
          index: "02"
          icon: "matrix"
          order: 1

          Field {
            label: "HEIGHT"
            hint: Settings.minBar + " TO " + Settings.maxBar + " PX"
            Gauge {
              from: Settings.minBar
              to: Settings.maxBar
              steps: (Settings.maxBar - Settings.minBar) / 2
              value: Settings.barHeight
              text: Settings.barHeight + "PX"
              onAdjusted: (v) => Settings.set("barHeight", Math.round(v))
            }
          }

          Field {
            label: "POSITION"
            hint: "MENUS OPEN FROM THE BAR"
            Choice {
              options: ["top", "bottom"]
              current: Settings.barPosition
              onPicked: (v) => Settings.set("barPosition", v)
            }
          }

          Field {
            label: "CLOCK SECONDS"
            Toggle {
              current: Settings.clockSeconds
              onPicked: (v) => Settings.set("clockSeconds", v)
            }
          }
        }

        Section {
          title: "PANELS"
          index: "03"
          icon: "hack"
          tone: Theme.secondary
          order: 2

          Field {
            label: "FROSTED GLASS"
            hint: "NIRI BLURS THE WALLPAPER BEHIND EVERY PANEL"
            Toggle {
              tone: Theme.secondary
              current: Settings.blur
              onPicked: (v) => Settings.set("blur", v)
            }
          }

          Field {
            label: "DROP SHADOWS"
            Toggle {
              tone: Theme.secondary
              current: Settings.shadows
              onPicked: (v) => Settings.set("shadows", v)
            }
          }

          Field {
            label: "PANEL OPACITY"
            hint: "LOWER LETS MORE FROST THROUGH"
            Gauge {
              tone: Theme.secondary
              from: 0.4
              to: 1
              steps: 12
              value: Settings.panelOpacity
              text: Math.round(Settings.panelOpacity * 100) + "%"
              onAdjusted: (v) => Settings.set("panelOpacity", Math.round(v * 100) / 100)
            }
          }

          Field {
            label: "DIM BEHIND MENUS"
            Gauge {
              tone: Theme.secondary
              from: 0
              to: 0.7
              steps: 14
              value: Settings.dim
              text: Math.round(Settings.dim * 100) + "%"
              onAdjusted: (v) => Settings.set("dim", Math.round(v * 100) / 100)
            }
          }
        }

        Section {
          title: "SENSORS & AUDIO"
          index: "04"
          icon: "cloud"
          tone: Theme.tertiary
          order: 3

          Field {
            label: "WEATHER"
            hint: "EMPTY: LOCATED FROM YOUR IP"
            Item {
              width: 260
              height: 30
              Entry {
                width: 260
                value: Settings.weatherLocation
                placeholder: Theme.config.weatherLocation || "AUTO"
                tone: Theme.tertiary
                onCommitted: (v) => Settings.set("weatherLocation", v)
              }
            }
          }

          Field {
            label: "UI SOUNDS"
            Toggle {
              tone: Theme.tertiary
              current: Sounds.fx
              onPicked: (v) => { Sounds.fx = v; Sounds.save() }
            }
          }

          Field {
            label: "CITY AMBIENCE"
            Toggle {
              tone: Theme.tertiary
              current: Sounds.ambience
              onPicked: (v) => { Sounds.ambience = v; Sounds.save() }
            }
          }

          Field {
            label: "VOLUME"
            Gauge {
              tone: Theme.tertiary
              value: Sounds.volume
              text: Math.round(Sounds.volume * 100) + "%"
              onAdjusted: (v) => { Sounds.volume = v; Sounds.save() }
            }
          }
        }

        Item {
          width: parent.width
          height: 36
          opacity: Math.min(1, window.reveal * 1.2)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 4
            text: "SAVED LIVE // " + Settings.path.replace(Theme.home, "~")
            color: Theme.muted
            font.family: Theme.fontMono
            font.pixelSize: 9
          }

          Action {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            label: "FACTORY RESET"
            tone: Theme.danger
            onTriggered: Settings.reset()
          }
        }
      }
    }
  }
}
