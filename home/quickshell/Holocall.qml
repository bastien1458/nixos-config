import QtQuick
import Quickshell
import Quickshell.Wayland

// The holocall, top left like in the game: the brick phone sending its waves,
// who is calling, and their portrait behind the red frame. Sounds rings it.
PanelWindow {
  id: window

  readonly property color frameTone: Theme.danger
  readonly property color nameTone: Theme.primary
  property real enter: Calls.active ? 1 : 0
  property int elapsed: 0

  Behavior on enter { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  screen: Hud.screenNamed(Hud.here())
  visible: enter > 0 && !Lock.locked
  color: "transparent"
  anchors {
    top: true
    left: true
  }
  margins {
    top: 10
    left: 16
  }
  exclusionMode: ExclusionMode.Normal
  implicitWidth: 360
  implicitHeight: Math.max(1, content.height)
  WlrLayershell.namespace: "cyberdeck-holocall"
  WlrLayershell.layer: WlrLayer.Overlay

  function clock(seconds) {
    const pad = v => (v < 10 ? "0" : "") + v
    return pad(Math.floor(seconds / 60)) + ":" + pad(seconds % 60)
  }

  function actionTone(label) {
    if (/accept|answer|join|r[ée]pondre|d[ée]crocher|rejoindre/i.test(label)) return Theme.ok
    if (/decline|reject|ignore|refuser|raccrocher/i.test(label)) return Theme.danger
    return window.nameTone
  }

  // a new caller, even over a ringing call, tears in again
  Connections {
    target: Calls
    function onSinceChanged() {
      window.elapsed = 0
      title.burst()
      flicker.restart()
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: Calls.active
    onTriggered: window.elapsed = Math.floor((Date.now() - Calls.since) / 1000)
  }

  Item {
    id: content
    width: parent.width
    height: frame.y + frame.height + (buttons.visible ? buttons.height + 10 : 0)
    opacity: window.enter
    transform: Translate { x: (1 - window.enter) * -40 }

    Icon {
      id: phone
      x: 0
      y: 8
      width: 36
      height: 36
      name: "phone"
      color: window.nameTone
      weight: 1.6
    }

    // in step with V's ringtone: one wave burst per ring
    Icon {
      anchors.fill: phone
      name: "waves"
      color: window.nameTone
      weight: 1.6

      SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: Calls.active
        NumberAnimation { to: 1; duration: 120 }
        PauseAnimation { duration: 700 }
        NumberAnimation { to: 0.15; duration: 300 }
        PauseAnimation { duration: 726 }
      }
    }

    Column {
      id: heading
      x: 48
      width: parent.width - x
      spacing: 0

      Text {
        text: "INCOMING CALL" + (Calls.app !== "" ? " // " + Calls.app.toUpperCase() : "")
        color: Theme.alpha(window.frameTone, 0.85)
        font.family: Theme.fontMono
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 2
      }

      GlitchText {
        id: title
        width: parent.width
        text: Calls.caller.toUpperCase()
        color: window.nameTone
        elide: Text.ElideRight
        font.family: Theme.fontUi
        font.pixelSize: 30
        font.weight: Font.Bold
        font.letterSpacing: 1
        minGap: 1800
        maxGap: 4000
      }
    }

    Item {
      id: frame
      x: heading.x
      y: heading.y + heading.height + 10
      width: 230
      height: 230

      SequentialAnimation on opacity {
        id: flicker
        running: false
        NumberAnimation { to: 0.2; duration: 40 }
        NumberAnimation { to: 1; duration: 50 }
        PauseAnimation { duration: 90 }
        NumberAnimation { to: 0.4; duration: 30 }
        NumberAnimation { to: 1; duration: 60 }
      }

      Plate {
        anchors.fill: parent
        cut: 14
        cutBL: 14
        fill: Theme.alpha(window.frameTone, 0.12)
        stroke: window.frameTone
        strokeW: 2
      }

      Item {
        id: portrait
        anchors.fill: parent
        anchors.margins: 7
        clip: true

        Image {
          id: photo
          anchors.fill: parent
          source: Calls.image
          sourceSize: Qt.size(256, 256)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          smooth: true
          visible: status === Image.Ready
        }

        // no picture: the app's icon, else a silhouette, as a hologram on the red screen
        Rectangle {
          anchors.fill: parent
          visible: !photo.visible
          color: Theme.alpha(window.frameTone, 0.18)

          HoloIcon {
            anchors.centerIn: parent
            width: 96
            height: 96
            visible: Calls.appIcon !== ""
            source: Calls.appIcon
            tone: window.nameTone
            glow: 0.6
          }

          Icon {
            anchors.centerIn: parent
            width: 120
            height: 120
            visible: Calls.appIcon === ""
            name: "user"
            color: window.nameTone
            weight: 1.2
          }
        }

        // the holocall's red cast and its scanlines
        Rectangle {
          anchors.fill: parent
          color: Theme.alpha(window.frameTone, 0.16)
        }

        Column {
          anchors.fill: parent
          Repeater {
            model: Math.ceil(portrait.height / 3)
            delegate: Item {
              width: portrait.width
              height: 3
              Rectangle { width: parent.width; height: 1; color: Qt.rgba(0, 0, 0, 0.28) }
            }
          }
        }

        Rectangle {
          id: sweep
          width: parent.width
          height: 26
          gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Theme.alpha(window.nameTone, 0.18) }
          }

          NumberAnimation on y {
            loops: Animation.Infinite
            running: Calls.active
            from: -sweep.height
            to: portrait.height
            duration: 1700
          }
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        height: 22
        color: Theme.alpha(Theme.bg, 0.85)
        border.color: window.frameTone
        border.width: 1

        Text {
          anchors.verticalCenter: parent.verticalCenter
          x: 8
          text: "RINGING // " + window.clock(window.elapsed)
          color: window.nameTone
          font.family: Theme.fontMono
          font.pixelSize: 10
          font.weight: Font.Bold
          font.letterSpacing: 1
        }
      }
    }

    Row {
      id: buttons
      x: frame.x
      y: frame.y + frame.height + 10
      spacing: 6
      visible: Calls.active

      Repeater {
        model: Calls.actions
        delegate: Item {
          id: action
          required property var modelData
          readonly property color tone: window.actionTone(modelData.text || "")
          width: actionText.implicitWidth + 18
          height: 24

          Plate {
            anchors.fill: parent
            cut: 6
            fill: Theme.alpha(action.tone, actionArea.containsMouse ? 0.28 : 0.1)
            stroke: action.tone
          }

          Text {
            id: actionText
            anchors.centerIn: parent
            text: (action.modelData.text || "OK").toUpperCase()
            color: action.tone
            font.family: Theme.fontUi
            font.pixelSize: 13
            font.weight: Font.Bold
          }

          Clickable {
            id: actionArea
            anchors.fill: parent
            onClicked: Calls.answer(action.modelData)
          }
        }
      }

      // silences the deck; the app keeps ringing in its own window
      Item {
        width: ignoreText.implicitWidth + 18
        height: 24

        Plate {
          anchors.fill: parent
          cut: 6
          fill: Theme.alpha(Theme.subtle, ignoreArea.containsMouse ? 0.22 : 0.06)
          stroke: Theme.alpha(Theme.subtle, 0.6)
        }

        Text {
          id: ignoreText
          anchors.centerIn: parent
          text: "IGNORE"
          color: Theme.subtle
          font.family: Theme.fontUi
          font.pixelSize: 13
          font.weight: Font.Bold
        }

        Clickable {
          id: ignoreArea
          anchors.fill: parent
          onClicked: Calls.stop()
        }
      }
    }
  }
}
