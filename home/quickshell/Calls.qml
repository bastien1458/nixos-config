pragma Singleton

import QtQuick
import Quickshell

// Incoming calls from any messenger, shown as the game's holocall. Apps that
// follow the notification spec tag them call.incoming; Electron apps like
// Discord send no category, so the text is matched too. A call rings until
// its app withdraws the notification, a call.ended / missed call notification
// of the same app comes in, it is answered or ignored, or 45 s pass.
Singleton {
  id: calls

  property bool active: false
  // null for a test call
  property var notification: null
  property string caller: ""
  property string app: ""
  property string image: ""
  property string appIcon: ""
  property var actions: []
  property real since: 0

  readonly property var ringWords: /incoming (?:voice |video |audio )?call|(?:is )?calling you|is calling|appel (?:vocal |audio |vid[ée]o )?entrant|vous appelle|t['’]appelle/i
  readonly property var endWords: /missed (?:voice |video )?call|call ended|appel (?:vocal |vid[ée]o )?manqu[ée]|appel termin[ée]/i

  // the app took the notification back: answered elsewhere, or the caller hung up
  readonly property bool withdrawn: notification !== null && Notifs.list.indexOf(notification) < 0
  onWithdrawnChanged: if (withdrawn) stop()

  function category(n) {
    return n.hints && n.hints.category ? String(n.hints.category) : ""
  }

  function text(n) {
    return (n.summary || "") + "\n" + (n.body || "")
  }

  function isCall(n) {
    const c = category(n)
    if (c === "call.incoming") return true
    // im.received and friends: a message saying "he is calling" is not a call
    if (c !== "" && c !== "call") return false
    return ringWords.test(text(n)) && !endWords.test(text(n))
  }

  function isHangUp(n) {
    const c = category(n)
    return c === "call.ended" || c === "call.unanswered" || endWords.test(text(n))
  }

  // "Jackie Welles is calling you" -> "Jackie Welles"
  function callerOf(n) {
    const words = new RegExp(ringWords.source, "ig")
    const clean = s => s.replace(words, "").replace(/^[\s:—–\-·|]+|[\s:—–\-·|.!…]+$/g, "")
    return clean(n.summary || "") || clean(n.body || "") || n.appName || "UNKNOWN"
  }

  function ring(n) {
    notification = n
    caller = callerOf(n)
    app = n.appName || ""
    image = n.image || ""
    appIcon = n.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""
    actions = n.actions || []
    start()
  }

  function test(name) {
    notification = null
    caller = name || "JACKIE WELLES"
    app = "CYBERDECK"
    image = ""
    appIcon = ""
    actions = []
    start()
  }

  function start() {
    since = Date.now()
    active = true
    timeout.restart()
  }

  // a call.ended or missed call of the app that is ringing
  function hangUpOn(n) {
    if (active && isHangUp(n) && (n.appName || "") === app) stop()
  }

  function answer(action) {
    action.invoke()
    stop()
  }

  // stops the deck ringing; the app keeps its own call window
  function stop() {
    active = false
    notification = null
    timeout.stop()
  }

  Timer {
    id: timeout
    interval: 45000
    onTriggered: calls.stop()
  }
}
