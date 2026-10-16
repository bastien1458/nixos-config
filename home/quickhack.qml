import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  // palette taken from the Cyberpunk 2077 quickhack screen
  readonly property color cyan: "#5ef6ff"
  readonly property color cyanSoft: "#3fd9e4"
  readonly property color cyanDim: "#1d7a84"
  readonly property color cyanDeep: "#10333b"
  readonly property color navy: "#e80a121b"
  readonly property color navyHi: "#f2102733"
  readonly property color red: "#ff5a50"
  readonly property color redSoft: "#ff6f66"
  readonly property color redDim: "#8a2a31"
  readonly property color redDeep: "#e82a0c12"
  readonly property color orange: "#ff9d3c"
  readonly property color amber: "#f2b84b"
  readonly property color paper: "#e8f7f8"
  readonly property string fontMain: "Rajdhani"
  readonly property string fontMono: "JetBrains Mono"

  property bool ready: false
  property string openedOnOutput: ""
  property var activeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

  property int tab: 0
  property int selected: 0
  property int armedIndex: -1
  property string query: ""
  property bool busy: false
  property bool listIntro: true
  property bool glitching: false
  property real upload: 0
  property real blink: 0
  property real segIntro: 0
  property point lastMouse: Qt.point(-9999, -9999)
  property real wheelAccum: 0
  property var pending: null

  property int ramTotal: 32
  property int ramFree: 32
  property string host: "nixos"

  readonly property var tabs: ["APPLICATIONS", "MENU"]
  readonly property var appItems: buildApps(DesktopEntries.applications.values, query)
  readonly property var menuItems: [
    { kind: "menu", name: "LOCK SCREEN", glyph: "LCK", cost: 2, category: "SECURITY", detail: "Locks the session behind swaylock.", command: ["swaylock"] },
    { kind: "menu", name: "SCREENSHOT", glyph: "SCR", cost: 1, category: "OPTICS", detail: "Opens the niri capture interface.", command: ["sh", "-c", "sleep 0.4; niri msg action screenshot"] },
    { kind: "menu", name: "AUDIO MIXER", glyph: "AUD", cost: 3, category: "AUDIO", detail: "Opens the PipeWire volume control.", command: ["pavucontrol"] },
    { kind: "menu", name: "MONITORS OFF", glyph: "MON", cost: 3, category: "OPTICS", detail: "Powers off every monitor until the next input.", command: ["niri", "msg", "action", "power-off-monitors"] },
    { kind: "menu", name: "SUSPEND", glyph: "SUS", cost: 4, category: "POWER", detail: "Suspends the machine to RAM.", command: ["systemctl", "suspend"] },
    { kind: "menu", name: "LOG OUT", glyph: "OUT", cost: 6, category: "SESSION", detail: "Terminates the niri session.", command: ["niri", "msg", "action", "quit", "--skip-confirmation"], danger: true },
    { kind: "menu", name: "REBOOT", glyph: "RBT", cost: 8, category: "POWER", detail: "Restarts the machine.", command: ["systemctl", "reboot"], danger: true },
    { kind: "menu", name: "POWER OFF", glyph: "PWR", cost: 10, category: "POWER", detail: "Shuts the machine down.", command: ["systemctl", "poweroff"], danger: true }
  ]
  readonly property var items: tab === 0 ? appItems : filterMenu(query)
  readonly property var current: items.length > 0 ? items[Math.min(selected, items.length - 1)] : null

  readonly property int segCount: Math.max(12, Math.min(48, ramTotal))
  readonly property int segFilled: Math.round(segCount * Math.min(1, ramFree / Math.max(1, ramTotal)))
  readonly property int segCost: current ? Math.min(current.cost, segFilled) : 0

  onQueryChanged: { selected = 0; armedIndex = -1 }
  onSelectedChanged: list.currentIndex = selected
  onItemsChanged: {
    if (selected >= items.length) selected = Math.max(0, items.length - 1)
    Qt.callLater(() => list.currentIndex = selected)
  }
  onReadyChanged: if (ready) intro.start()

  function toArr(list) {
    const out = []
    if (!list) return out
    for (let i = 0; i < list.length; i++) out.push(list[i])
    return out
  }

  function costOf(name) {
    let h = 7
    for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 9973
    return 1 + h % 9
  }

  function glyphOf(name) {
    const words = name.replace(/[^A-Za-z0-9 ]/g, " ").split(" ").filter(w => w.length > 0)
    if (words.length >= 2) return words.slice(0, 3).map(w => w[0]).join("").toUpperCase()
    return (words[0] || "APP").slice(0, 3).toUpperCase()
  }

  function iconFor(icon) {
    if (!icon) return ""
    if (icon.startsWith("/")) return "file://" + icon
    return Quickshell.iconPath(icon, true)
  }

  function categoryOf(categories) {
    const map = [
      ["Development", "DEVELOPMENT"], ["Game", "ENTERTAINMENT"], ["AudioVideo", "MEDIA"], ["Audio", "MEDIA"],
      ["Video", "MEDIA"], ["Graphics", "GRAPHICS"], ["Network", "NETWORK"], ["Office", "OFFICE"],
      ["Science", "SCIENCE"], ["Education", "EDUCATION"], ["Settings", "SETTINGS"], ["System", "SYSTEM"],
      ["Utility", "UTILITY"]
    ]
    for (const pair of map) if (categories.indexOf(pair[0]) >= 0) return pair[1]
    return "APPLICATION"
  }

  function buildApps(entries, q) {
    const needle = q.toLowerCase()
    const out = []
    const seen = {}
    const list = toArr(entries)
    for (const e of list) {
      if (!e || e.noDisplay) continue
      const name = e.name || e.id
      if (seen[name]) continue
      seen[name] = true
      const keywords = toArr(e.keywords).join(" ")
      let score = 0
      if (needle.length > 0) {
        const lower = name.toLowerCase()
        if (lower.startsWith(needle)) score = 0
        else if (lower.indexOf(needle) >= 0) score = 1
        else if ((e.genericName + " " + keywords + " " + e.id).toLowerCase().indexOf(needle) >= 0) score = 2
        else continue
      }
      out.push({
        kind: "app",
        entry: e,
        name: name.toUpperCase(),
        rawName: name,
        generic: e.genericName || "",
        comment: e.comment || "",
        category: categoryOf(toArr(e.categories)),
        icon: iconFor(e.icon),
        glyph: glyphOf(name),
        cost: costOf(name),
        terminal: e.runInTerminal,
        exec: e.execString || toArr(e.command).join(" "),
        id: e.id,
        score: score
      })
    }
    out.sort((a, b) => a.score - b.score || a.rawName.localeCompare(b.rawName))
    return out
  }

  function filterMenu(q) {
    const needle = q.toLowerCase()
    return menuItems.filter(m => needle.length === 0 || m.name.toLowerCase().indexOf(needle) >= 0 || m.detail.toLowerCase().indexOf(needle) >= 0)
  }

  function esc(text) {
    return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  function hl(text) {
    return "<font color='#ff9d3c'>" + esc(text) + "</font>"
  }

  function bulletsFor(item, armed) {
    if (!item) return ["No quickhack matches " + hl(query.toUpperCase()) + "."]
    if (item.kind === "app") {
      const exec = item.exec.length > 64 ? item.exec.slice(0, 61) + "..." : item.exec
      return [
        (item.generic ? hl(item.generic) + ". " : "") + esc(item.comment || "No description provided by the desktop entry."),
        "Executes " + hl(exec) + (item.terminal ? " inside a " + hl("Kitty") + " session." : "."),
        "Spawns on the " + hl("focused workspace") + " of the current output."
      ]
    }
    const out = [esc(item.detail), "Executes " + hl(item.command.join(" ")) + "."]
    if (item.danger) out.push(armed ? hl("Press ENTER again to confirm the upload.") : "Requires " + hl("confirmation") + " before upload.")
    return out
  }

  function parseSystem(text) {
    const total = /MemTotal:\s+(\d+)/.exec(text)
    const avail = /MemAvailable:\s+(\d+)/.exec(text)
    const name = /HOST=(\S+)/.exec(text)
    if (total) ramTotal = Math.max(1, Math.round(parseInt(total[1]) / 1048576))
    if (avail) ramFree = Math.round(parseInt(avail[1]) / 1048576)
    if (name) host = name[1]
  }

  function setOutputFromJson(text) {
    try {
      const outputName = JSON.parse(text).name
      if (openedOnOutput === "") {
        openedOnOutput = outputName
        for (const screen of Quickshell.screens) {
          if (screen.name === outputName) {
            activeScreen = screen
            break
          }
        }
        ready = true
      } else if (outputName !== openedOnOutput) {
        close()
      }
    } catch (error) {
      console.log("Unable to read focused output: " + error)
      ready = true
    }
  }

  function select(index) {
    if (items.length === 0) return
    const next = Math.max(0, Math.min(items.length - 1, index))
    if (next !== selected) armedIndex = -1
    selected = next
  }

  function setTab(index) {
    if (index === tab) return
    listIntro = true
    tab = index
    selected = 0
    armedIndex = -1
    listIntroTimer.restart()
    glitchBurst.restart()
  }

  function run(item) {
    if (item.kind !== "app") {
      Quickshell.execDetached(item.command)
    } else if (item.terminal) {
      Quickshell.execDetached(["kitty", "-e"].concat(toArr(item.entry.command)))
    } else {
      item.entry.execute()
    }
  }

  function execute() {
    const item = current
    if (!item || busy) return
    if (item.danger && armedIndex !== selected) {
      armedIndex = selected
      return
    }
    busy = true
    pending = item
    uploadAnim.start()
  }

  function close() {
    if (outro.running) return
    busy = true
    outro.start()
  }

  function handleKey(event) {
    if (busy) {
      event.accepted = true
      return
    }
    const key = event.key
    const plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
    if (key === Qt.Key_Escape) { if (query.length > 0) query = ""; else close() }
    else if (key === Qt.Key_Return || key === Qt.Key_Enter) execute()
    else if (key === Qt.Key_Up) select(selected - 1)
    else if (key === Qt.Key_Down) select(selected + 1)
    else if (key === Qt.Key_PageUp) select(selected - 5)
    else if (key === Qt.Key_PageDown) select(selected + 5)
    else if (key === Qt.Key_Home) select(0)
    else if (key === Qt.Key_End) select(items.length - 1)
    else if (key === Qt.Key_Tab) setTab((tab + 1) % tabs.length)
    else if (key === Qt.Key_Backtab) setTab((tab + tabs.length - 1) % tabs.length)
    else if (key === Qt.Key_Left) setTab(Math.max(0, tab - 1))
    else if (key === Qt.Key_Right) setTab(Math.min(tabs.length - 1, tab + 1))
    else if (key === Qt.Key_Backspace) query = query.slice(0, -1)
    else if (plain && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) query += event.text
    else return
    event.accepted = true
  }

  function hoverAt(area, mouse, index) {
    const p = area.mapToItem(null, mouse.x, mouse.y)
    if (lastMouse.x < -9000) {
      lastMouse = p
      return
    }
    if (Math.abs(p.x - lastMouse.x) + Math.abs(p.y - lastMouse.y) > 3) {
      lastMouse = p
      if (!busy) select(index)
    }
  }

  // ---------------------------------------------------------------- processes

  Process {
    id: focusedOutput
    command: ["niri", "msg", "-j", "focused-output"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.setOutputFromJson(this.text)
    }
  }

  Process {
    id: systemInfo
    command: ["sh", "-c", "cat /proc/meminfo; echo HOST=$(uname -n)"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.parseSystem(this.text)
    }
  }

  Timer {
    interval: 250
    running: root.ready && !root.busy
    repeat: true
    onTriggered: focusedOutput.exec(focusedOutput.command)
  }

  Timer {
    interval: 400
    running: !root.ready
    onTriggered: root.ready = true
  }

  Timer {
    id: listIntroTimer
    interval: 650
    onTriggered: root.listIntro = false
  }

  Timer {
    id: glitchBurst
    interval: 140
    onTriggered: root.glitching = false
    onRunningChanged: if (running) root.glitching = true
  }

  // ---------------------------------------------------------------- animations

  SequentialAnimation on blink {
    loops: Animation.Infinite
    running: true
    NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
    NumberAnimation { to: 0; duration: 420; easing.type: Easing.InOutSine }
  }

  ParallelAnimation {
    id: intro
    ScriptAction { script: { root.glitching = true; listIntroTimer.restart(); hud.forceActiveFocus() } }
    NumberAnimation { target: backdrop; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
    NumberAnimation { target: sweep; property: "y"; from: -sweep.height; to: panel.height; duration: 650; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "segIntro"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }
    SequentialAnimation {
      NumberAnimation { target: hud; property: "opacity"; from: 0; to: 1; duration: 60 }
      NumberAnimation { target: hud; property: "opacity"; to: 0.25; duration: 40 }
      NumberAnimation { target: hud; property: "opacity"; to: 1; duration: 50 }
      NumberAnimation { target: hud; property: "opacity"; to: 0.6; duration: 30 }
      NumberAnimation { target: hud; property: "opacity"; to: 1; duration: 60 }
      ScriptAction { script: root.glitching = false }
    }
    SequentialAnimation {
      NumberAnimation { target: hud; property: "x"; from: -14; to: 9; duration: 50 }
      NumberAnimation { target: hud; property: "x"; to: -5; duration: 40 }
      NumberAnimation { target: hud; property: "x"; to: 0; duration: 60 }
    }
  }

  SequentialAnimation {
    id: uploadAnim
    NumberAnimation { target: root; property: "upload"; from: 0; to: 1; duration: 300; easing.type: Easing.InOutQuad }
    ScriptAction { script: root.run(root.pending) }
    PauseAnimation { duration: 90 }
    ScriptAction { script: root.close() }
  }

  SequentialAnimation {
    id: outro
    ScriptAction { script: root.glitching = true }
    ParallelAnimation {
      SequentialAnimation {
        NumberAnimation { target: hud; property: "x"; to: 10; duration: 40 }
        NumberAnimation { target: hud; property: "x"; to: -7; duration: 40 }
        NumberAnimation { target: hud; property: "x"; to: 0; duration: 40 }
      }
      SequentialAnimation {
        NumberAnimation { target: hud; property: "opacity"; to: 0.3; duration: 40 }
        NumberAnimation { target: hud; property: "opacity"; to: 0.8; duration: 30 }
        NumberAnimation { target: hud; property: "opacity"; to: 0; duration: 90 }
      }
      NumberAnimation { target: backdrop; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
    }
    ScriptAction { script: Qt.quit() }
  }

  // ---------------------------------------------------------------- building blocks

  // Dark panel with the chamfered corners used everywhere in the game UI.
  component Plate: Shape {
    id: plate
    property real cut: 10
    property real cutBL: 0
    property color fill: "#e80a121b"
    property color stroke: "#1d7a84"
    property real strokeW: 1
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: plate.fill
      strokeColor: plate.stroke
      strokeWidth: plate.strokeW
      joinStyle: ShapePath.MiterJoin
      startX: 0
      startY: 0
      PathLine { x: plate.width - plate.cut; y: 0 }
      PathLine { x: plate.width; y: plate.cut }
      PathLine { x: plate.width; y: plate.height }
      PathLine { x: plate.cutBL; y: plate.height }
      PathLine { x: 0; y: plate.height - plate.cutBL }
      PathLine { x: 0; y: 0 }
    }
  }

  // READY / TRACEABLE style tag.
  component Chip: Rectangle {
    id: chip
    property string label: ""
    property color tone: "#5ef6ff"
    property bool flashing: false
    property real pulse: 0
    width: chipText.implicitWidth + 12
    height: 18
    color: Qt.rgba(tone.r, tone.g, tone.b, 0.08 + pulse * 0.35)
    border.color: tone
    border.width: 1

    Text {
      id: chipText
      anchors.centerIn: parent
      text: chip.label
      color: chip.tone
      font.family: "Rajdhani"
      font.pixelSize: 12
      font.weight: Font.Bold
      font.letterSpacing: 1
    }

    SequentialAnimation on pulse {
      running: chip.flashing
      loops: Animation.Infinite
      onRunningChanged: if (!running) chip.pulse = 0
      NumberAnimation { to: 1; duration: 180 }
      NumberAnimation { to: 0; duration: 180 }
    }
  }

  // Keyboard hint box, cyan outline like in the game footer.
  component KeyCap: Rectangle {
    id: cap
    property string label: ""
    property color tone: "#5ef6ff"
    width: Math.max(26, capText.implicitWidth + 12)
    height: 26
    color: "#cc071016"
    border.color: tone
    border.width: 1

    Text {
      id: capText
      anchors.centerIn: parent
      text: cap.label
      color: cap.tone
      font.family: "Rajdhani"
      font.pixelSize: 15
      font.weight: Font.Bold
    }
  }

  // Text that "decrypts" from random glyphs every time its source changes.
  component DecodeText: Text {
    id: decoder
    property string source: ""
    property real progress: 1
    readonly property string glyphs: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#$%&@/\\<>[]"
    text: progress >= 1 ? source : scramble(source, progress)

    function scramble(value, amount) {
      const solved = Math.floor(value.length * amount)
      let out = ""
      for (let i = 0; i < value.length; i++) {
        const c = value[i]
        out += (i < solved || c === " ") ? c : glyphs[Math.floor(Math.random() * glyphs.length)]
      }
      return out
    }

    onSourceChanged: decodeAnim.restart()
    NumberAnimation { id: decodeAnim; target: decoder; property: "progress"; from: 0; to: 1; duration: 320 }
  }

  // App icon rendered as a monochrome hologram, falling back to a glyph.
  component HoloIcon: Item {
    id: holo
    property string source: ""
    property string glyph: ""
    property color tone: "#5ef6ff"
    property real glow: 0
    property int glyphSize: 15

    Image {
      id: holoImage
      anchors.fill: parent
      source: holo.source
      sourceSize: Qt.size(128, 128)
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      smooth: true
      mipmap: true
      visible: false
    }

    MultiEffect {
      anchors.fill: holoImage
      source: holoImage
      visible: holoImage.status === Image.Ready
      colorization: 1
      colorizationColor: holo.tone
      brightness: 0.25
      contrast: 0.25
      shadowEnabled: holo.glow > 0
      shadowColor: holo.tone
      shadowBlur: holo.glow
      shadowHorizontalOffset: 0
      shadowVerticalOffset: 0
    }

    Text {
      anchors.centerIn: parent
      visible: holoImage.status !== Image.Ready
      text: holo.glyph
      color: holo.tone
      font.family: "Rajdhani"
      font.pixelSize: holo.glyphSize
      font.weight: Font.Bold
      font.letterSpacing: 1
    }
  }

  // ---------------------------------------------------------------- window

  PanelWindow {
    id: panel
    visible: root.ready
    screen: root.activeScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickhack"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }

    // scanner tint over the desktop
    Item {
      id: backdrop
      anchors.fill: parent
      opacity: 0

      Rectangle {
        anchors.fill: parent
        color: "#b0080103"
      }

      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: "transparent"
          fillGradient: RadialGradient {
            centerX: panel.width / 2
            centerY: panel.height / 2
            centerRadius: panel.width * 0.62
            focalX: centerX
            focalY: centerY
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.55; color: "#26300306" }
            GradientStop { position: 1.0; color: "#e6000000" }
          }
          startX: 0
          startY: 0
          PathLine { x: panel.width; y: 0 }
          PathLine { x: panel.width; y: panel.height }
          PathLine { x: 0; y: panel.height }
          PathLine { x: 0; y: 0 }
        }
      }

      Canvas {
        anchors.fill: parent
        opacity: 0.09
        onPaint: {
          const ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          ctx.fillStyle = "#ff4a3a"
          for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
        }
      }

      Rectangle {
        id: sweep
        width: parent.width
        height: 180
        y: -height
        gradient: Gradient {
          GradientStop { position: 0.0; color: "#00ff3b3b" }
          GradientStop { position: 0.92; color: "#33ff3b3b" }
          GradientStop { position: 1.0; color: "#aaff5a50" }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()
      }
    }

    Item {
      id: hud
      width: parent.width
      height: parent.height
      opacity: 0
      focus: true
      Keys.onPressed: (event) => root.handleKey(event)

      // ------------------------------------------------ frame decorations

      Rectangle { x: 0; y: 10; width: parent.width * 0.55; height: 2; color: root.red; opacity: 0.45 }
      Text { x: 24; y: 20; text: "SCANNER // " + root.host.toUpperCase(); color: root.red; opacity: 0.7; font.family: root.fontMono; font.pixelSize: 10 }
      Text { x: 24; y: 40; text: "≡"; color: root.red; opacity: 0.8; font.pixelSize: 22 }
      Text { x: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 30; text: "≡"; color: root.red; opacity: 0.8; font.pixelSize: 22 }
      Text { anchors.right: parent.right; anchors.rightMargin: 24; y: 40; text: "≡"; color: root.red; opacity: 0.8; font.pixelSize: 22 }

      // ------------------------------------------------ cyberdeck RAM

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(panel.height * 0.055)
        spacing: 6

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "CYBERDECK RAM: " + root.ramFree + "/" + root.ramTotal
          color: root.redSoft
          font.family: root.fontMain
          font.pixelSize: 18
          font.weight: Font.Bold
          font.letterSpacing: 1.5
        }

        Item {
          width: segRow.width + 20
          height: 44

          Rectangle { width: parent.width; height: 1; color: root.red; opacity: 0.5 }
          Rectangle { width: 1; height: 10; color: root.red; opacity: 0.7 }
          Rectangle { x: parent.width - 1; width: 1; height: 10; color: root.red; opacity: 0.7 }

          Row {
            id: segRow
            x: 10
            y: 8
            spacing: 3

            Repeater {
              model: root.segCount
              delegate: Rectangle {
                required property int index
                readonly property bool filled: index < root.segFilled
                readonly property bool preview: filled && index >= root.segFilled - root.segCost
                width: 9
                height: 30
                opacity: index / root.segCount <= root.segIntro ? 1 : 0.08
                color: !filled ? root.cyanDeep
                     : preview ? (root.upload > 0 ? Qt.tint(root.cyanDeep, Qt.rgba(0.37, 0.96, 1, 1 - root.upload)) : Qt.tint(root.cyanSoft, Qt.rgba(1, 1, 1, root.blink * 0.75)))
                     : root.cyanSoft
                border.color: preview ? root.paper : "transparent"
                border.width: preview ? 1 : 0
              }
            }
          }
        }
      }

      // ------------------------------------------------ quickhack list

      MouseArea {
        id: leftCol
        x: Math.round(panel.width * 0.065)
        width: 560
        height: Math.min(800, panel.height - 220)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 20
        acceptedButtons: Qt.LeftButton
        onWheel: (wheel) => {
          root.wheelAccum += wheel.angleDelta.y
          while (Math.abs(root.wheelAccum) >= 120) {
            root.select(root.selected + (root.wheelAccum > 0 ? -1 : 1))
            root.wheelAccum -= root.wheelAccum > 0 ? 120 : -120
          }
        }

        Text {
          text: "CYBERDECK V 2.0.77 // NIXOS"
          color: root.red
          opacity: 0.7
          font.family: root.fontMono
          font.pixelSize: 10
        }

        Rectangle { y: 16; width: 300; height: 1; color: root.redDim }

        Row {
          y: 24
          spacing: 12

          Text {
            text: "AVAILABLE QUICKHACKS:"
            color: root.paper
            font.family: root.fontMain
            font.pixelSize: 21
            font.weight: Font.Bold
            font.letterSpacing: 1
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.query.length > 0 ? "> " + root.query.toUpperCase() : "TYPE TO FILTER"
            color: root.query.length > 0 ? root.cyan : root.cyanDim
            font.family: root.fontMain
            font.pixelSize: 17
            font.weight: Font.DemiBold
            font.letterSpacing: 1
          }

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 9
            height: 18
            color: root.cyan
            opacity: root.blink > 0.5 ? 0.9 : 0
          }
        }

        // tabs, styled like the DATA / HACKING tabs
        Item {
          id: tabBar
          y: 62
          width: 430
          height: 36

          Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cyanDim }

          Row {
            spacing: 6

            Repeater {
              model: root.tabs
              delegate: Item {
                id: tabItem
                required property var modelData
                required property int index
                readonly property bool active: index === root.tab
                width: 208
                height: 36

                Plate {
                  anchors.fill: parent
                  cut: 12
                  fill: tabItem.active ? "#f20b1a23" : root.redDeep
                  stroke: tabItem.active ? root.cyan : root.redDim
                  strokeW: tabItem.active ? 1.5 : 1
                }

                Row {
                  anchors.left: parent.left
                  anchors.leftMargin: 14
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 10

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: tabItem.modelData
                    color: tabItem.active ? root.cyan : root.red
                    font.family: root.fontMain
                    font.pixelSize: 19
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                  }

                  KeyCap {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !tabItem.active
                    label: "TAB"
                    tone: "#9aa4ad"
                    height: 22
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: root.setTab(tabItem.index)
                }
              }
            }
          }

          Rectangle {
            x: root.tab * 214 + 8
            y: parent.height - 2
            width: 192
            height: 3
            color: root.cyan
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          }
        }

        ListView {
          id: list
          x: -24
          y: 108
          width: parent.width + 24
          height: parent.height - y
          clip: true
          interactive: false
          spacing: 8
          topMargin: 14
          bottomMargin: 14
          model: root.items
          Component.onCompleted: currentIndex = root.selected
          highlight: Item {}
          highlightFollowsCurrentItem: true
          highlightRangeMode: ListView.ApplyRange
          preferredHighlightBegin: height * 0.32
          preferredHighlightEnd: height * 0.68
          highlightMoveDuration: 220
          highlightMoveVelocity: -1

          delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool isCurrent: index === root.selected
            readonly property bool danger: modelData.danger === true
            readonly property bool armed: danger && root.armedIndex === index
            readonly property real dist: (y - list.contentY + height / 2 - list.height / 2) / (list.height / 2)
            readonly property color tone: danger ? root.red : root.cyan
            property real intro: root.listIntro ? 0 : 1
            property real shift: isCurrent ? 16 : 0
            property real jitter: 0
            width: list.width
            height: 66

            Behavior on shift { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

            Component.onCompleted: if (root.listIntro) introAnim.start()
            onIsCurrentChanged: if (isCurrent) selectAnim.restart()

            SequentialAnimation {
              id: introAnim
              PauseAnimation { duration: Math.min(row.index, 12) * 32 }
              NumberAnimation { target: row; property: "intro"; to: 1; duration: 260; easing.type: Easing.OutCubic }
            }

            ParallelAnimation {
              id: selectAnim
              NumberAnimation { target: flash; property: "opacity"; from: 0.4; to: 0; duration: 260; easing.type: Easing.OutQuad }
              SequentialAnimation {
                NumberAnimation { target: row; property: "jitter"; to: 6; duration: 30 }
                NumberAnimation { target: row; property: "jitter"; to: -4; duration: 30 }
                NumberAnimation { target: row; property: "jitter"; to: 2; duration: 30 }
                NumberAnimation { target: row; property: "jitter"; to: 0; duration: 30 }
              }
            }

            Item {
              id: card
              width: 430
              height: parent.height
              x: 32 + 70 * row.dist * row.dist + row.shift + row.jitter - (1 - row.intro) * 110
              opacity: row.intro
              layer.enabled: row.isCurrent
              layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: row.tone
                shadowBlur: 0.7
                shadowOpacity: 0.85
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: 24
              }

              Plate {
                anchors.fill: parent
                cut: 12
                cutBL: 6
                fill: row.danger ? (row.isCurrent ? "#f23a0f18" : root.redDeep) : (row.isCurrent ? root.navyHi : root.navy)
                stroke: row.isCurrent ? row.tone : (row.danger ? root.redDim : root.cyanDim)
                strokeW: row.isCurrent ? 2 : 1
              }

              Rectangle {
                x: 0
                y: 12
                width: 3
                height: parent.height - 24
                color: row.tone
                opacity: row.isCurrent ? 1 : 0.45
              }

              Rectangle {
                id: flash
                anchors.fill: parent
                anchors.margins: 2
                color: row.tone
                opacity: 0
              }

              Column {
                x: 22
                width: parent.width - 22 - 160
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                  width: parent.width
                  text: row.modelData.name
                  color: row.isCurrent ? Qt.lighter(row.tone, 1.25) : row.tone
                  elide: Text.ElideRight
                  font.family: root.fontMain
                  font.pixelSize: 24
                  font.weight: Font.DemiBold
                  font.letterSpacing: 0.5
                }

                Row {
                  spacing: 5

                  Chip {
                    label: row.armed ? "CONFIRM" : (row.danger ? "CRITICAL" : "READY")
                    tone: row.tone
                    flashing: row.armed
                  }

                  Chip {
                    visible: row.modelData.terminal === true
                    label: "TERMINAL"
                    tone: root.amber
                  }
                }
              }

              Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "↓"
                  color: row.tone
                  font.family: root.fontMono
                  font.pixelSize: 20
                  font.weight: Font.Bold
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: row.modelData.cost
                  color: row.isCurrent ? root.paper : row.tone
                  font.family: root.fontMain
                  font.pixelSize: 32
                  font.weight: Font.Bold
                }

                Plate {
                  anchors.verticalCenter: parent.verticalCenter
                  width: 8
                  height: 24
                  cut: 3
                  fill: "transparent"
                  stroke: row.tone
                  strokeW: 2
                }

                Item {
                  width: 52
                  height: 52

                  Plate {
                    anchors.fill: parent
                    cut: 10
                    cutBL: 6
                    fill: row.danger ? "#cc3a0f18" : "#cc0b1d26"
                    stroke: row.isCurrent ? row.tone : (row.danger ? root.redDim : root.cyanDim)
                  }

                  HoloIcon {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    source: row.modelData.icon || ""
                    glyph: row.modelData.glyph
                    tone: row.tone
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: (mouse) => root.hoverAt(card, mouse, row.index)
                onClicked: {
                  root.select(row.index)
                  root.execute()
                }
              }
            }
          }
        }

        Text {
          visible: root.items.length === 0
          y: list.y + 30
          x: 20
          text: "NO TARGET // 0 QUICKHACKS FOUND"
          color: root.red
          font.family: root.fontMain
          font.pixelSize: 22
          font.weight: Font.Bold
          opacity: root.blink * 0.5 + 0.5
        }
      }

      // ------------------------------------------------ target in the middle

      Item {
        id: reticle
        anchors.centerIn: parent
        width: 1
        height: 1
        property real lock: 1

        Connections {
          target: root
          function onCurrentChanged() { lockAnim.restart() }
        }

        NumberAnimation { id: lockAnim; target: reticle; property: "lock"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }

        Rectangle {
          anchors.centerIn: parent
          width: 640
          height: 640
          radius: 320
          color: "transparent"
          border.color: root.red
          border.width: 1
          opacity: 0.16
        }

        Repeater {
          model: 15
          delegate: Rectangle {
            required property int index
            visible: index % 5 !== 2
            x: (index % 5 - 2) * 96 - 6
            y: (Math.floor(index / 5) - 1) * 76 - 6
            width: 12
            height: 12
            color: "transparent"
            border.color: root.red
            border.width: 1
            opacity: 0.55
          }
        }

        Repeater {
          model: 2
          delegate: Column {
            required property int index
            x: index === 0 ? -300 : 286
            y: -150
            spacing: 4

            Repeater {
              model: 14
              delegate: Text {
                required property int index
                text: "<"
                rotation: 90
                color: root.red
                opacity: index === 7 ? 1 : 0.35 + 0.4 * (1 - Math.abs(index - 7) / 7)
                font.family: root.fontMain
                font.pixelSize: 14
                font.weight: Font.Bold
              }
            }
          }
        }

        Text { x: -340; y: -12; text: "1x"; color: root.red; font.family: root.fontMain; font.pixelSize: 18; font.weight: Font.Bold }
        Text { x: 312; y: -12; text: (root.items.length / 10).toFixed(1); color: root.red; font.family: root.fontMain; font.pixelSize: 18; font.weight: Font.Bold }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          y: -215
          spacing: 10

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            rotation: 45
            color: "transparent"
            border.color: root.cyan
            border.width: 2
          }

          DecodeText {
            source: root.current ? root.current.name : "NO TARGET"
            color: root.paper
            font.family: root.fontMain
            font.pixelSize: 22
            font.weight: Font.Bold
            font.letterSpacing: 1.5
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: -150
          text: "▾"
          color: root.orange
          font.pixelSize: 18
        }

        Item {
          id: hologram
          width: 190
          height: 190
          x: -width / 2
          y: -height / 2 + 10
          scale: 0.92 + 0.08 * reticle.lock
          opacity: 0.5 + 0.5 * reticle.lock

          HoloIcon {
            anchors.fill: parent
            source: root.current ? (root.current.icon || "") : ""
            glyph: root.current ? root.current.glyph : "--"
            tone: root.current && root.current.danger ? root.red : root.orange
            glow: 0.8
            glyphSize: 72

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              NumberAnimation { to: 0.82; duration: 90 }
              NumberAnimation { to: 1; duration: 60 }
              PauseAnimation { duration: 1700 }
              NumberAnimation { to: 0.7; duration: 40 }
              NumberAnimation { to: 1; duration: 80 }
              PauseAnimation { duration: 2400 }
            }
          }

          Column {
            anchors.fill: parent
            spacing: 3
            Repeater {
              model: 48
              delegate: Rectangle { width: hologram.width; height: 1; color: "#000000"; opacity: 0.25 }
            }
          }

          Repeater {
            model: 4
            delegate: Item {
              required property int index
              readonly property real spread: 34 * (1 - reticle.lock)
              x: (index % 2 === 0 ? -12 - spread : hologram.width - 10 + spread)
              y: (index < 2 ? -12 - spread : hologram.height - 10 + spread)
              width: 22
              height: 22

              Rectangle {
                x: index % 2 === 0 ? 0 : parent.width - width
                y: index < 2 ? 0 : parent.height - height
                width: 22
                height: 2
                color: root.cyan
              }

              Rectangle {
                x: index % 2 === 0 ? 0 : parent.width - width
                y: index < 2 ? 0 : parent.height - height
                width: 2
                height: 22
                color: root.cyan
              }
            }
          }
        }

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          y: 140
          spacing: 6
          opacity: root.upload > 0 ? 1 : 0

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "UPLOADING QUICKHACK  " + Math.round(root.upload * 100) + "%"
            color: root.cyan
            font.family: root.fontMain
            font.pixelSize: 16
            font.weight: Font.Bold
            font.letterSpacing: 1.5
          }

          Rectangle {
            width: 280
            height: 8
            color: root.cyanDeep
            border.color: root.cyanDim
            border.width: 1

            Rectangle {
              width: parent.width * root.upload
              height: parent.height
              color: root.cyan
            }
          }
        }
      }

      // ------------------------------------------------ detail panel

      MouseArea {
        id: intel
        width: 440
        height: 480
        anchors.right: parent.right
        anchors.rightMargin: Math.round(panel.width * 0.06)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -10
        acceptedButtons: Qt.LeftButton
        property real refresh: 1

        Connections {
          target: root
          function onCurrentChanged() { intelAnim.restart() }
        }

        NumberAnimation { id: intelAnim; target: intel; property: "refresh"; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic }

        Item {
          width: parent.width
          height: 34

          Plate {
            x: 0
            width: 150
            height: parent.height
            cut: 12
            fill: root.redDeep
            stroke: root.redDim
          }

          Row {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "DATA"
              color: root.red
              font.family: root.fontMain
              font.pixelSize: 18
              font.weight: Font.Bold
              font.letterSpacing: 1.5
            }

            KeyCap {
              anchors.verticalCenter: parent.verticalCenter
              label: String(root.items.length)
              tone: "#9aa4ad"
              height: 22
            }
          }

          Plate {
            x: 156
            width: parent.width - 156
            height: parent.height
            cut: 12
            fill: "#f20b1a23"
            stroke: root.cyan
            strokeW: 1.5
          }

          Text {
            x: 172
            anchors.verticalCenter: parent.verticalCenter
            text: "HACKING"
            color: root.cyan
            font.family: root.fontMain
            font.pixelSize: 18
            font.weight: Font.Bold
            font.letterSpacing: 1.5
          }
        }

        Plate {
          y: 40
          width: parent.width
          height: parent.height - 40
          cut: 20
          cutBL: 10
          fill: "#ee0a131c"
          stroke: root.cyanDim
        }

        Rectangle {
          x: 1
          y: 41 + (parent.height - 42) * intel.refresh
          width: parent.width - 2
          height: 2
          color: root.cyan
          opacity: 1 - intel.refresh
        }

        Column {
          x: 22
          y: 60
          width: parent.width - 44
          spacing: 14
          opacity: 0.4 + 0.6 * intel.refresh

          DecodeText {
            width: parent.width
            source: root.current ? root.current.name : "NO TARGET"
            color: root.current && root.current.danger ? root.red : root.cyan
            elide: Text.ElideRight
            font.family: root.fontMain
            font.pixelSize: 30
            font.weight: Font.Bold
            font.letterSpacing: 1
          }

          Chip {
            label: (root.current ? root.current.category : "UNKNOWN") + " QUICKHACK"
            tone: root.paper
            height: 22
          }

          Column {
            spacing: 4

            Repeater {
              model: root.current ? [
                "Upload Time: 0.3 sec",
                "RAM Cost: " + root.current.cost + " units",
                root.current.kind === "app" ? "Source: " + root.current.id : "Source: system"
              ] : []
              delegate: Row {
                required property var modelData
                spacing: 8

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: 8
                  height: 8
                  radius: 4
                  color: "transparent"
                  border.color: root.paper
                  border.width: 1
                }

                Text {
                  text: modelData
                  color: root.paper
                  font.family: root.fontMain
                  font.pixelSize: 17
                  font.weight: Font.Medium
                }
              }
            }
          }

          Rectangle { width: parent.width; height: 1; color: root.cyanDim; opacity: 0.6 }

          Column {
            width: parent.width
            spacing: 10

            Repeater {
              model: root.bulletsFor(root.current, root.armedIndex === root.selected)
              delegate: Row {
                required property var modelData
                width: parent.width
                spacing: 10

                Rectangle {
                  y: 8
                  width: 6
                  height: 6
                  radius: 3
                  color: root.paper
                }

                Text {
                  width: parent.width - 16
                  text: modelData
                  textFormat: Text.StyledText
                  wrapMode: Text.Wrap
                  color: root.paper
                  font.family: root.fontMain
                  font.pixelSize: 18
                  font.weight: Font.Medium
                  lineHeight: 1.05
                }
              }
            }
          }
        }

        Text {
          x: 22
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 12
          text: "◎ OS  KIROSHI // NIXOS"
          color: root.cyanDim
          font.family: root.fontMain
          font.pixelSize: 13
          font.weight: Font.Bold
          font.letterSpacing: 1
        }
      }

      // ------------------------------------------------ footer

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(panel.height * 0.85)
        width: 330
        height: 42

        Plate {
          anchors.fill: parent
          cut: 10
          fill: root.navy
          stroke: root.cyanDim
        }

        Text {
          x: 18
          anchors.verticalCenter: parent.verticalCenter
          text: "RAM COST"
          color: root.cyan
          font.family: root.fontMain
          font.pixelSize: 18
          font.weight: Font.Bold
          font.letterSpacing: 1.5
        }

        Row {
          anchors.right: parent.right
          anchors.rightMargin: 16
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.current ? root.current.cost : 0
            color: root.cyan
            font.family: root.fontMain
            font.pixelSize: 24
            font.weight: Font.Bold
          }

          Plate {
            anchors.verticalCenter: parent.verticalCenter
            width: 7
            height: 20
            cut: 3
            fill: "transparent"
            stroke: root.cyan
            strokeW: 2
          }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        text: "NC " + Qt.formatDateTime(new Date(), "dd.MM.yyyy  HH:mm") + "  //  " + root.host.toUpperCase()
        color: root.red
        opacity: 0.7
        font.family: root.fontMono
        font.pixelSize: 10
      }

      Row {
        anchors.right: parent.right
        anchors.rightMargin: Math.round(panel.width * 0.04)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 26

        Repeater {
          model: [
            { key: "↵", label: "EXECUTE" },
            { key: "TAB", label: "CHANGE TAB" },
            { key: "↑↓", label: "SELECT" },
            { key: "ESC", label: "EXIT" }
          ]
          delegate: Row {
            required property var modelData
            spacing: 8

            KeyCap { label: modelData.key }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.label
              color: root.redSoft
              font.family: root.fontMain
              font.pixelSize: 17
              font.weight: Font.Bold
              font.letterSpacing: 1
            }
          }
        }
      }
    }

    // glitch blocks flashing during transitions
    Item {
      anchors.fill: parent
      visible: root.glitching

      Repeater {
        id: glitchBlocks
        model: 8
        delegate: Rectangle {
          required property int index
          color: index % 3 === 0 ? root.red : root.cyan
          opacity: 0
        }
      }

      Timer {
        interval: 40
        repeat: true
        running: root.glitching
        triggeredOnStart: true
        onTriggered: {
          for (let i = 0; i < glitchBlocks.count; i++) {
            const block = glitchBlocks.itemAt(i)
            block.x = Math.random() * panel.width * 0.8
            block.y = Math.random() * panel.height
            block.width = 60 + Math.random() * 420
            block.height = 2 + Math.random() * 10
            block.opacity = Math.random() * 0.45
          }
        }
      }
    }
  }
}
