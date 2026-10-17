pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon (replaces mako). Popups are a subset of the
// tracked notifications; the control center shows the whole log.
Singleton {
  id: notifs

  readonly property var list: server.trackedNotifications.values
  readonly property int count: list.length
  property var popups: []
  readonly property var shown: popups.filter(n => list.indexOf(n) >= 0)

  signal arrived(var notification)

  function drop(n) {
    popups = popups.filter(p => p !== n)
  }

  function dismiss(n) {
    drop(n)
    n.dismiss()
  }

  function clear() {
    popups = []
    for (const n of list.slice()) n.dismiss()
  }

  function isCritical(n) {
    return n.urgency === NotificationUrgency.Critical
  }

  NotificationServer {
    id: server
    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: false
    imageSupported: true
    persistenceSupported: true

    onNotification: (n) => {
      n.tracked = true
      // a call gets the holocall instead of a popup; one carried over from
      // before a reload has stopped ringing long ago
      if (!n.lastGeneration && Calls.isCall(n)) {
        Calls.ring(n)
      } else {
        Calls.hangUpOn(n)
        if (!Hud.dnd || n.urgency === NotificationUrgency.Critical)
          notifs.popups = [n].concat(notifs.popups).slice(0, 4)
      }
      notifs.arrived(n)
    }
  }
}
