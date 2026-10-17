pragma Singleton

import QtQuick
import Quickshell

// Incoming calls from any messenger, shown as the game's holocall. Apps that
// follow the notification spec tag them call.incoming. Discord has no call
// notification at all: a call only shows up as the message notification of
// the DM's call message, "<name> started a call." / "<name> a commencé un
// appel.", so that text is matched, plus the usual "is calling you" wordings.
// A call rings until its app closes the notification (Discord does when its
// window opens that DM), the app's window gets the focus, a call.ended /
// missed call notification of the same app comes in, it is answered or
// ignored, or 45 s pass: Discord never says the caller hung up.
Singleton {
  id: calls

  property bool active: false
  // null for a test call
  property var notification: null
  property string caller: ""
  property string app: ""
  property string entry: ""
  property string image: ""
  property string appIcon: ""
  property var actions: []
  property real since: 0

  readonly property var ringWords: /incoming (?:voice |video |audio )?call|(?:is )?calling you|is calling|appel (?:vocal |audio |vid[ée]o )?entrant|vous appelle|t['’]appelle/i
  readonly property var endWords: /missed (?:voice |video )?call|call ended|appel (?:vocal |vid[ée]o )?manqu[ée]|appel termin[ée]/i
  // anchored at the end: "started a call that lasted 5 minutes." is history, not a ring
  readonly property var discordRing: /\s(?:started a call|a commenc[ée] un appel)\.?\s*$/i

  function category(n) {
    return n.hints && n.hints.category ? String(n.hints.category) : ""
  }

  function text(n) {
    return (n.summary || "") + "\n" + (n.body || "")
  }

  function isDiscordRing(n) {
    const sender = (n.appName || "") + " " + (n.desktopEntry || "")
    return /discord/i.test(sender) && discordRing.test(n.body || "")
  }

  function isCall(n) {
    const c = category(n)
    if (c === "call.incoming") return true
    if (c === "call.ended" || c === "call.unanswered") return false
    if (isDiscordRing(n)) return true
    // whatever the category: messengers file their calls under im.* too
    return ringWords.test(text(n)) && !endWords.test(text(n))
  }

  function isHangUp(n) {
    const c = category(n)
    return c === "call.ended" || c === "call.unanswered" || endWords.test(text(n))
  }

  // "Jackie Welles is calling you" -> "Jackie Welles"; for Discord the body
  // names the caller, the summary of a group DM is "Name (Group)"
  function callerOf(n) {
    if (isDiscordRing(n))
      return (n.body || "").replace(discordRing, "").trim() || (n.summary || "").replace(/\s*\([^)]*\)\s*$/, "") || "UNKNOWN"
    const words = new RegExp(ringWords.source, "ig")
    const clean = s => s.replace(words, "").replace(/^[\s:—–\-·|]+|[\s:—–\-·|.!…]+$/g, "")
    return clean(n.summary || "") || clean(n.body || "") || n.appName || "UNKNOWN"
  }

  function ring(n) {
    notification = n
    caller = callerOf(n)
    app = n.appName || ""
    entry = n.desktopEntry || ""
    image = n.image || ""
    appIcon = n.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""
    actions = n.actions || []
    start()
  }

  function test(name) {
    notification = null
    caller = name || "JACKIE WELLES"
    app = "CYBERDECK"
    entry = ""
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

  // invoking closes the notification, which takes its actions with it: stop first
  function answer(action) {
    stop()
    action.invoke()
  }

  // stops the deck ringing; the app keeps its own call window
  function stop() {
    active = false
    notification = null
    actions = []
    timeout.stop()
  }

  // the window of the ringing app, by its niri app_id
  function isAppWindow(w) {
    const id = w && w.app_id ? String(w.app_id).toLowerCase() : ""
    return id !== "" && (id === entry.toLowerCase() || id === app.toLowerCase())
  }

  // Quickshell lists a notification only after onNotification returns, so the
  // list cannot tell a closed call from a new one: its closed signal can
  Connections {
    target: calls.notification
    ignoreUnknownSignals: true
    function onClosed(reason) { calls.stop() }
  }

  // going to the app to pick up silences the deck
  Connections {
    target: Niri
    function onFocusedWindowIdChanged() {
      if (calls.active && calls.isAppWindow(Niri.focusedWindow)) calls.stop()
    }
  }

  Timer {
    id: timeout
    interval: 45000
    onTriggered: calls.stop()
  }
}
