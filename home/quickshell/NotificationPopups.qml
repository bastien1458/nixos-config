import QtQuick
import Quickshell
import Quickshell.Wayland

// Incoming transmissions, stacked under the bar on the focused output.
PanelWindow {
  id: window

  screen: Hud.screenNamed(Hud.here())
  visible: Notifs.shown.length > 0 && !Lock.locked
  color: "transparent"
  anchors {
    top: true
    right: true
  }
  margins {
    top: 4
    right: 12
  }
  exclusionMode: ExclusionMode.Normal
  implicitWidth: 400
  implicitHeight: Math.max(1, stack.height)
  WlrLayershell.namespace: "cyberdeck-notifications"
  WlrLayershell.layer: WlrLayer.Overlay

  Column {
    id: stack
    width: parent.width
    spacing: 8

    Repeater {
      model: Notifs.shown
      delegate: Item {
        id: card
        required property var modelData
        readonly property bool critical: Notifs.isCritical(modelData)
        readonly property color tone: critical ? Theme.danger : Theme.tertiary
        readonly property int timeout: critical ? 0 : (modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : 6500)
        property real life: 1
        property real enter: 0
        width: stack.width
        height: body.height + 26
        opacity: enter
        transform: Translate { x: (1 - card.enter) * 60 }

        Component.onCompleted: enterAnim.start()

        NumberAnimation { id: enterAnim; target: card; property: "enter"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }

        NumberAnimation {
          target: card
          property: "life"
          from: 1
          to: 0
          duration: card.timeout
          running: card.timeout > 0
          paused: area.containsMouse
          onFinished: Notifs.drop(card.modelData)
        }

        Plate {
          anchors.fill: parent
          cut: 14
          cutBL: 6
          fill: Theme.alpha(Theme.bg, 0.95)
          stroke: card.tone
        }

        Rectangle { x: 0; y: 10; width: 3; height: parent.height - 20; color: card.tone }

        Rectangle {
          anchors.bottom: parent.bottom
          x: 6
          width: (parent.width - 12) * card.life
          height: 2
          color: card.tone
          visible: card.timeout > 0
        }

        Row {
          id: body
          x: 14
          y: 12
          width: parent.width - 28
          spacing: 12

          Item {
            width: 40
            height: 40
            visible: icon.source != ""

            Rectangle {
              anchors.fill: parent
              color: Theme.alpha(card.tone, 0.08)
              border.color: Theme.alpha(card.tone, 0.4)
              border.width: 1
            }

            HoloIcon {
              id: icon
              anchors.fill: parent
              anchors.margins: 6
              source: card.modelData.image || (card.modelData.appIcon ? Quickshell.iconPath(card.modelData.appIcon, true) : "")
              tone: card.tone
            }
          }

          Column {
            width: parent.width - (icon.source != "" ? 52 : 0)
            spacing: 3

            Row {
              spacing: 8

              Text {
                text: card.critical ? "PRIORITY TRANSMISSION" : "INCOMING // " + (card.modelData.appName || "UNKNOWN").toUpperCase()
                color: card.tone
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.weight: Font.Bold
                font.letterSpacing: 1
              }
            }

            DecodeText {
              width: parent.width
              source: card.modelData.summary || ""
              color: Theme.fg
              elide: Text.ElideRight
              font.family: Theme.fontUi
              font.pixelSize: 17
              font.weight: Font.Bold
            }

            Text {
              width: parent.width
              visible: text !== ""
              text: card.modelData.body || ""
              color: Theme.subtle
              wrapMode: Text.Wrap
              maximumLineCount: 4
              elide: Text.ElideRight
              font.family: Theme.fontUi
              font.pixelSize: 14
              font.weight: Font.Medium
            }

            Row {
              spacing: 6
              visible: card.modelData.actions && card.modelData.actions.length > 0

              Repeater {
                model: card.modelData.actions || []
                delegate: Item {
                  id: action
                  required property var modelData
                  width: actionText.implicitWidth + 16
                  height: 22

                  Plate {
                    anchors.fill: parent
                    cut: 5
                    fill: Theme.alpha(card.tone, actionArea.containsMouse ? 0.25 : 0.08)
                    stroke: card.tone
                  }

                  Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: (action.modelData.text || "OK").toUpperCase()
                    color: card.tone
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    font.weight: Font.Bold
                  }

                  Clickable {
                    id: actionArea
                    anchors.fill: parent
                    onClicked: {
                      action.modelData.invoke()
                      Notifs.drop(card.modelData)
                    }
                  }
                }
              }
            }
          }
        }

        MouseArea {
          id: area
          anchors.fill: parent
          z: -1
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: (mouse) => mouse.button === Qt.RightButton ? Notifs.dismiss(card.modelData) : Notifs.drop(card.modelData)
        }
      }
    }
  }
}
