import QtQuick

// Visual of an OS: the official logo of its manufacturer. Only entries
// without a corporation (the Blackwall) fall back to a drawn emblem.
Item {
  id: badge

  property string osId: Theme.os
  property string logo: Theme.osInfo.logo || ""
  property color color: Theme.primary
  property real weight: 3

  Logo {
    anchors.fill: parent
    visible: badge.logo !== ""
    corp: badge.logo
    mark: true
    color: badge.color
  }

  Icon {
    anchors.fill: parent
    visible: badge.logo === ""
    emblem: true
    name: badge.osId
    color: badge.color
    weight: badge.weight
  }
}
