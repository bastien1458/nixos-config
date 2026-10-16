import QtQuick
import QtQuick.Shapes

// Breach Protocol: the code matrix mini-game, rules as in the game.
// Pick in the top row first, then alternate column / row from the last pick,
// and fit the daemon sequences into the buffer before the timer runs out.
Item {
  id: game

  signal closeRequested()
  signal finished(int eddies, bool perfect, bool blackwall, var installed)

  // ------------------------------------------------------------ state

  readonly property var codes: ["1C", "55", "BD", "E9", "7A", "FF"]
  readonly property var pool: [
    [
      { name: "DATAMINE_V1", desc: "Extracts a small amount of eurodollars." },
      { name: "ICEPICK", desc: "Lowers the RAM cost of every quickhack on this deck." },
      { name: "CAMERA SHUTDOWN", desc: "Blinds every optic on the local subnet." }
    ],
    [
      { name: "DATAMINE_V2", desc: "Extracts a moderate amount of eurodollars." },
      { name: "MASS VULNERABILITY", desc: "Strips the physical resistances of every target." },
      { name: "FRIENDLY TURRETS", desc: "Rewrites the IFF tables of the local turrets." }
    ],
    [
      { name: "DATAMINE_V3", desc: "Extracts a large amount of eurodollars and components." },
      { name: "DATAMINE_MASTERY", desc: "Pulls the whole access point, shard by shard." },
      { name: "NEUTRALIZE MALWARE", desc: "Purges every hostile daemon from the network." }
    ]
  ]
  readonly property var rewards: [[80, 200], [250, 500], [600, 1200]]

  property int size: 6
  property int bufferSize: 6
  property var matrix: []
  property var used: []
  property var buffer: []
  property var daemons: []
  property bool rowMode: true
  property int line: 0
  property int cursor: 0
  property int hovered: -1
  property real timeLimit: 50
  property real timeLeft: 50
  property bool started: false
  property bool over: false
  property string outcome: ""
  property int earned: 0
  property bool perfect: false
  property bool breachedWall: false
  property real intro: 0

  readonly property var bufferCodes: buffer.map(i => matrix[i])
  readonly property string hoverCode: hovered >= 0 && canPick(hovered) ? matrix[hovered] : ""
  readonly property real cell: Math.min(64, Math.floor(Math.min(height * 0.5, 470) / size))

  function rnd(n) {
    return Math.floor(Math.random() * n)
  }

  function rowOf(i) { return Math.floor(i / size) }
  function colOf(i) { return i % size }

  function cellOnLine(k) {
    return rowMode ? line * size + k : k * size + line
  }

  function canPick(i) {
    if (over || i < 0 || used[i]) return false
    return rowMode ? rowOf(i) === line : colOf(i) === line
  }

  // ------------------------------------------------------------ generation

  function newBreach() {
    const roll = Math.random()
    const n = roll < 0.35 ? 5 : (roll < 0.8 ? 6 : 7)
    const buf = n + rnd(2)
    const alphabet = codes.slice(0, n === 7 ? 6 : 5)

    // a guaranteed solution: a legal path through the matrix
    let r = 0
    let c = rnd(n)
    const path = [c]
    for (let step = 1; step < buf; step++) {
      const options = []
      for (let k = 0; k < n; k++) {
        const candidate = step % 2 === 1 ? k * n + c : r * n + k
        if (path.indexOf(candidate) < 0) options.push(candidate)
      }
      const pick = options[rnd(options.length)]
      r = Math.floor(pick / n)
      c = pick % n
      path.push(pick)
    }
    const values = path.map(() => alphabet[rnd(alphabet.length)])

    // daemons are windows of the solution, so all of them always fit
    const lengths = [2, 3, buf >= 7 ? 4 : 3]
    const list = []
    const seen = {}
    for (let tier = 0; tier < 3; tier++) {
      let seq = []
      for (let attempt = 0; attempt < 12; attempt++) {
        const start = rnd(buf - lengths[tier] + 1)
        seq = values.slice(start, start + lengths[tier])
        if (!seen[seq.join(" ")]) break
      }
      seen[seq.join(" ")] = true
      const info = pool[tier][rnd(pool[tier].length)]
      const span = rewards[tier]
      list.push({ name: info.name, desc: info.desc, seq: seq, tier: tier, hidden: false,
                  reward: span[0] + rnd(span[1] - span[0]), state: "pending", progress: 0 })
    }
    // something else sometimes answers from behind the wall
    if (n >= 6 && Math.random() < 0.12) {
      const start = rnd(buf - 3)
      list.push({ name: "▓▒░ UNKNOWN DAEMON", desc: "Signature matches no known construct. It has been waiting for you.",
                  seq: values.slice(start, start + 4), tier: 3, hidden: true, reward: 2077, state: "pending", progress: 0 })
    }

    const grid = []
    for (let i = 0; i < n * n; i++) grid.push(alphabet[rnd(alphabet.length)])
    path.forEach((cellIndex, k) => grid[cellIndex] = values[k])

    size = n
    bufferSize = buf
    matrix = grid
    used = grid.map(() => false)
    buffer = []
    daemons = list
    rowMode = true
    line = 0
    cursor = 0
    hovered = -1
    timeLimit = 30 + n * 4
    timeLeft = timeLimit
    started = false
    over = false
    outcome = ""
    earned = 0
    perfect = false
    breachedWall = false
    introAnim.restart()
  }

  // ------------------------------------------------------------ rules

  function progressOf(seq, buf) {
    for (let s = 0; s + seq.length <= buf.length; s++) {
      let hit = true
      for (let j = 0; j < seq.length; j++) {
        if (buf[s + j] !== seq[j]) { hit = false; break }
      }
      if (hit) return seq.length
    }
    for (let k = Math.min(seq.length - 1, buf.length); k > 0; k--) {
      let hit = true
      for (let j = 0; j < k; j++) {
        if (buf[buf.length - k + j] !== seq[j]) { hit = false; break }
      }
      if (hit) return k
    }
    return 0
  }

  function anyPickable() {
    for (let k = 0; k < size; k++) if (canPick(cellOnLine(k))) return true
    return false
  }

  function pick(i) {
    if (!canPick(i)) return
    started = true
    const nextUsed = used.slice()
    nextUsed[i] = true
    used = nextUsed
    buffer = buffer.concat([i])
    const wasRow = rowMode
    rowMode = !wasRow
    line = wasRow ? colOf(i) : rowOf(i)
    cursor = wasRow ? rowOf(i) : colOf(i)
    hovered = -1
    pickFlash.restart()
    evaluate(false)
  }

  function evaluate(timeout) {
    const buf = buffer.map(i => matrix[i])
    const remaining = bufferSize - buf.length
    const stuck = !timeout && !anyPickable()
    daemons = daemons.map(d => {
      if (d.state !== "pending") return d
      const p = progressOf(d.seq, buf)
      const next = Object.assign({}, d, { progress: p })
      if (p === d.seq.length) next.state = "installed"
      else if (timeout || stuck || d.seq.length - p > remaining) next.state = "failed"
      return next
    })
    if (timeout || stuck || remaining === 0 || daemons.every(d => d.state !== "pending")) conclude(timeout)
  }

  function conclude(timeout) {
    if (over) return
    over = true
    const visible = daemons.filter(d => !d.hidden)
    const installed = daemons.filter(d => d.state === "installed")
    earned = installed.reduce((sum, d) => sum + d.reward, 0)
    perfect = visible.every(d => d.state === "installed")
    breachedWall = daemons.some(d => d.hidden && d.state === "installed")
    if (perfect) earned += 250
    outcome = timeout ? "BREACH TIMED OUT" : perfect ? "BREACH SUCCESSFUL" : installed.length > 0 ? "PARTIAL BREACH" : "BREACH FAILED"
    resultAnim.restart()
    finished(earned, perfect, breachedWall, installed.map(d => d.name))
  }

  // ------------------------------------------------------------ input

  function moveCursor(delta) {
    for (let step = 1; step <= size; step++) {
      const k = (cursor + delta * step + size * 4) % size
      if (canPick(cellOnLine(k))) {
        cursor = k
        hovered = cellOnLine(k)
        return
      }
    }
  }

  function handleKey(event) {
    const key = event.key
    if (key === Qt.Key_Escape) closeRequested()
    else if (over && (key === Qt.Key_R || key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)) newBreach()
    else if (key === Qt.Key_R) newBreach()
    else if (over) return
    else if (key === Qt.Key_Left || key === Qt.Key_Up || key === Qt.Key_H || key === Qt.Key_K) moveCursor(-1)
    else if (key === Qt.Key_Right || key === Qt.Key_Down || key === Qt.Key_L || key === Qt.Key_J) moveCursor(1)
    else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) pick(hovered >= 0 ? hovered : cellOnLine(cursor))
    else return
    event.accepted = true
  }

  Keys.onPressed: (event) => handleKey(event)

  Timer {
    interval: 50
    repeat: true
    running: game.started && !game.over && game.visible
    onTriggered: {
      game.timeLeft = Math.max(0, game.timeLeft - 0.05)
      if (game.timeLeft <= 0) game.evaluate(true)
    }
  }

  NumberAnimation { id: introAnim; target: game; property: "intro"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }

  Component.onCompleted: newBreach()

  // ------------------------------------------------------------ layout

  readonly property real matrixW: Math.max(cell * size + 40, 440)
  readonly property real gridX: (matrixW - cell * size) / 2
  readonly property real rightW: 620
  readonly property real totalW: matrixW + 40 + rightW

  Item {
    id: stage
    width: game.totalW
    height: 640
    anchors.centerIn: parent

    // ---------------------------------------------- top strip

    Row {
      y: -70
      spacing: 14
      opacity: game.intro

      Logo {
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        corp: Theme.osInfo.logo || ""
        color: Theme.primary
        mark: true
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: (Theme.osInfo.maker || "NETWATCH") + " // BREACH PROTOCOL"
        color: Theme.primary
        font.family: Theme.fontUi
        font.pixelSize: 22
        font.weight: Font.Bold
        font.letterSpacing: 2
      }
    }

    Rectangle {
      x: game.matrixW + 40
      y: -66
      width: game.rightW
      height: 22
      color: Theme.primary
      opacity: game.intro

      Text {
        anchors.centerIn: parent
        text: "BREACH PROTOCOL INTERFACE"
        color: Theme.bg
        font.family: Theme.fontMono
        font.pixelSize: 9
        font.letterSpacing: 2
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "EXUMER 62UZ-FFLH-9YLT-E327"
        color: Theme.alpha(Theme.bg, 0.65)
        font.family: Theme.fontMono
        font.pixelSize: 8
      }
    }

    // ---------------------------------------------- timer

    Item {
      id: timerBox
      width: game.matrixW
      height: 64
      opacity: game.intro

      Text {
        y: 8
        text: "BREACH TIME REMAINING"
        color: game.timeLeft < 8 && game.started ? Theme.danger : Theme.primary
        font.family: Theme.fontUi
        font.pixelSize: 24
        font.weight: Font.Bold
        font.letterSpacing: 1
      }

      Rectangle {
        anchors.right: parent.right
        y: 2
        width: 96
        height: 38
        color: "transparent"
        border.color: game.timeLeft < 8 && game.started ? Theme.danger : Theme.primary
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: game.timeLeft.toFixed(2)
          color: game.timeLeft < 8 && game.started ? Theme.danger : Theme.primary
          font.family: Theme.fontUi
          font.pixelSize: 26
          font.weight: Font.DemiBold
        }
      }

      Rectangle {
        y: 50
        width: parent.width
        height: 6
        color: Theme.primaryDeep

        Rectangle {
          width: parent.width * (game.timeLeft / game.timeLimit)
          height: parent.height
          color: game.timeLeft < 8 && game.started ? Theme.danger : Theme.primary
        }
      }
    }

    // ---------------------------------------------- code matrix

    Item {
      id: matrixPanel
      y: 90
      width: game.matrixW
      height: game.cell * game.size + 64
      opacity: game.intro
      transform: Translate { x: (1 - game.intro) * -40 }

      Plate {
        anchors.fill: parent
        cut: 0
        fill: Theme.alpha(Theme.bg, 0.85)
        stroke: Theme.frame
      }

      Header {
        width: parent.width
        label: "CODE MATRIX"
        index: "A-" + (game.size * 91 + game.bufferSize)
        icon: "matrix"
      }

      // active row / column band
      Rectangle {
        id: band
        x: game.rowMode ? 1 : game.gridX + game.line * game.cell
        y: game.rowMode ? 44 + game.line * game.cell : 29
        width: game.rowMode ? parent.width - 2 : game.cell
        height: game.rowMode ? game.cell : parent.height - 30
        color: Theme.alpha(Theme.primary, 0.1)
        border.color: Theme.alpha(Theme.primary, 0.25)
        border.width: 1
        visible: !game.over
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      }

      Grid {
        id: grid
        x: game.gridX
        y: 44
        columns: game.size

        Repeater {
          model: game.matrix.length
          delegate: Item {
            id: cellItem
            required property int index
            readonly property bool taken: game.used[index] === true
            readonly property bool live: game.canPick(index)
            readonly property bool hot: game.hovered === index && live
            readonly property real wave: Math.max(0, Math.min(1, game.intro * 2.2 - (game.rowOf(index) + game.colOf(index)) / (game.size * 2)))
            width: game.cell
            height: game.cell

            Rectangle {
              anchors.centerIn: parent
              width: game.cell * 0.72
              height: game.cell * 0.72
              color: cellItem.hot ? Theme.alpha(Theme.primary, 0.18) : "transparent"
              border.color: Theme.primary
              border.width: cellItem.hot ? 1.5 : 0
            }

            DecodeText {
              anchors.centerIn: parent
              source: cellItem.taken ? "[ ]" : (cellItem.wave >= 1 ? game.matrix[cellItem.index] : "")
              progress: cellItem.wave >= 1 ? 1 : 0
              duration: 260
              color: cellItem.taken ? Theme.alpha(Theme.muted, 0.6)
                   : cellItem.hot ? Theme.white
                   : cellItem.live ? Theme.primary
                   : game.over ? Theme.alpha(Theme.primary, 0.3) : Theme.alpha(Theme.primary, 0.55)
              font.family: Theme.fontUi
              font.pixelSize: Math.round(game.cell * 0.4)
              font.weight: Font.DemiBold
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: cellItem.live ? Qt.PointingHandCursor : Qt.ArrowCursor
              onEntered: if (cellItem.live) {
                game.hovered = cellItem.index
                game.cursor = game.rowMode ? game.colOf(cellItem.index) : game.rowOf(cellItem.index)
              }
              onExited: if (game.hovered === cellItem.index) game.hovered = -1
              onClicked: game.pick(cellItem.index)
            }
          }
        }
      }

      Brackets {
        anchors.fill: parent
        anchors.margins: -6
        tone: Theme.frame
        len: 14
      }

      // outcome banner
      Item {
        id: banner
        anchors.centerIn: parent
        width: parent.width + 60
        height: 120
        visible: game.over
        opacity: 0

        Plate {
          anchors.fill: parent
          cut: 16
          cutBL: 16
          fill: Theme.alpha(Theme.bg, 0.96)
          stroke: game.perfect ? Theme.ok : (game.earned > 0 ? Theme.warn : Theme.danger)
          strokeW: 2
        }

        Column {
          anchors.centerIn: parent
          spacing: 6

          DecodeText {
            anchors.horizontalCenter: parent.horizontalCenter
            source: game.outcome
            color: game.perfect ? Theme.ok : (game.earned > 0 ? Theme.warn : Theme.danger)
            font.family: Theme.fontUi
            font.pixelSize: 34
            font.weight: Font.Bold
            font.letterSpacing: 3
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: game.breachedWall ? "SOMETHING CAME THROUGH. NEW OS SIGNATURE DETECTED."
                : game.earned > 0 ? "+ " + game.earned.toLocaleString(Qt.locale("en_US"), "f", 0) + " €$ TRANSFERRED" + (game.perfect ? "  //  PERFECT BONUS" : "")
                : "ICE HELD. NO DATA EXTRACTED."
            color: game.breachedWall ? Theme.danger : Theme.fg
            font.family: Theme.fontUi
            font.pixelSize: 17
            font.weight: Font.DemiBold
            font.letterSpacing: 1
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "PRESS R TO JACK IN AGAIN"
            color: Theme.subtle
            font.family: Theme.fontUi
            font.pixelSize: 13
            font.weight: Font.Bold
            font.letterSpacing: 2
          }
        }
      }
    }

    // ---------------------------------------------- buffer

    Item {
      x: game.matrixW + 40
      width: game.rightW
      height: 80
      opacity: game.intro

      Text {
        y: 0
        text: "BUFFER"
        color: Theme.primary
        font.family: Theme.fontUi
        font.pixelSize: 24
        font.weight: Font.Bold
        font.letterSpacing: 1
      }

      Rectangle {
        y: 32
        width: bufferRow.width + 20
        height: 48
        color: Theme.alpha(Theme.bg, 0.85)
        border.color: Theme.primary
        border.width: 1

        Row {
          id: bufferRow
          x: 10
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Repeater {
            model: game.bufferSize
            delegate: Item {
              id: slot
              required property int index
              readonly property bool filled: index < game.buffer.length
              readonly property bool ghost: index === game.buffer.length && game.hoverCode !== ""
              width: 34
              height: 34

              Shape {
                anchors.fill: parent
                visible: !slot.filled
                ShapePath {
                  strokeColor: Theme.alpha(Theme.primary, 0.55)
                  strokeWidth: 1
                  fillColor: "transparent"
                  strokeStyle: ShapePath.DashLine
                  dashPattern: [3, 3]
                  startX: 0.5
                  startY: 0.5
                  PathLine { x: 33.5; y: 0.5 }
                  PathLine { x: 33.5; y: 33.5 }
                  PathLine { x: 0.5; y: 33.5 }
                  PathLine { x: 0.5; y: 0.5 }
                }
              }

              Rectangle {
                anchors.fill: parent
                visible: slot.filled
                color: Theme.alpha(Theme.primary, 0.12)
                border.color: Theme.primary
                border.width: 1
              }

              Text {
                anchors.centerIn: parent
                text: slot.filled ? game.bufferCodes[slot.index] : (slot.ghost ? game.hoverCode : "")
                color: slot.filled ? Theme.primary : Theme.alpha(Theme.primary, 0.45)
                font.family: Theme.fontUi
                font.pixelSize: 17
                font.weight: Font.DemiBold
              }
            }
          }
        }
      }
    }

    // ---------------------------------------------- daemons

    Item {
      x: game.matrixW + 40
      y: 120
      width: game.rightW
      height: daemonCol.height + 50
      opacity: game.intro
      transform: Translate { x: (1 - game.intro) * 40 }

      Plate {
        anchors.fill: parent
        cut: 0
        fill: Theme.alpha(Theme.bg, 0.85)
        stroke: Theme.frame
      }

      Header {
        width: parent.width
        label: "SEQUENCE REQUIRED TO UPLOAD"
        index: "DAEMONS " + game.daemons.length
        icon: "hack"
        solid: false
      }

      Column {
        id: daemonCol
        x: 16
        y: 42
        width: parent.width - 32
        spacing: 14

        Repeater {
          model: game.daemons
          delegate: Item {
            id: daemon
            required property var modelData
            required property int index
            readonly property bool installed: modelData.state === "installed"
            readonly property bool failed: modelData.state === "failed"
            readonly property color tone: modelData.hidden ? Theme.danger : (installed ? Theme.ok : (failed ? Theme.muted : Theme.primary))
            width: parent.width
            height: 54

            Rectangle {
              anchors.fill: parent
              color: daemon.installed ? Theme.alpha(Theme.ok, 0.08) : (daemon.modelData.hidden ? Theme.alpha(Theme.danger, 0.06) : "transparent")
            }

            Row {
              x: 6
              anchors.verticalCenter: parent.verticalCenter
              spacing: 6

              Repeater {
                model: daemon.modelData.seq
                delegate: Rectangle {
                  id: codeBox
                  required property string modelData
                  required property int index
                  readonly property bool matched: daemon.installed || index < daemon.modelData.progress
                  readonly property bool nextUp: !daemon.installed && !daemon.failed && index === daemon.modelData.progress
                  readonly property bool wouldHit: nextUp && game.hoverCode === modelData
                  width: 34
                  height: 34
                  color: matched ? Theme.alpha(daemon.tone, 0.85) : (wouldHit ? Theme.alpha(Theme.primary, 0.25) : "transparent")
                  border.color: nextUp ? Theme.primary : Theme.alpha(daemon.tone, 0.35)
                  border.width: nextUp ? 1.5 : 1

                  Text {
                    anchors.centerIn: parent
                    text: codeBox.modelData
                    color: codeBox.matched ? Theme.bg : (daemon.failed ? Theme.alpha(Theme.muted, 0.7) : daemon.tone)
                    font.family: Theme.fontUi
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.strikeout: daemon.failed
                  }
                }
              }
            }

            Column {
              x: 4 * 40 + 24
              width: parent.width - x - 100
              anchors.verticalCenter: parent.verticalCenter
              spacing: 1

              GlitchText {
                text: daemon.modelData.name
                color: daemon.failed ? Theme.muted : (daemon.modelData.hidden ? Theme.danger : Theme.fg)
                font.family: Theme.fontUi
                font.pixelSize: 18
                font.weight: Font.Bold
                font.letterSpacing: 1
                active: daemon.modelData.hidden
              }

              Text {
                width: parent.width
                text: daemon.modelData.desc
                color: daemon.failed ? Theme.alpha(Theme.muted, 0.7) : Theme.subtle
                elide: Text.ElideRight
                font.family: Theme.fontUi
                font.pixelSize: 14
                font.weight: Font.Medium
              }
            }

            Chip {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              label: daemon.installed ? "INSTALLED" : daemon.failed ? "FAILED" : (daemon.modelData.hidden ? "███ €$" : daemon.modelData.reward + " €$")
              tone: daemon.installed ? Theme.ok : (daemon.failed ? Theme.danger : (daemon.modelData.hidden ? Theme.danger : Theme.primary))
              solid: daemon.installed
              size: 13
            }
          }
        }
      }
    }

    // ---------------------------------------------- footer

    Row {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      spacing: 22
      opacity: game.intro

      Repeater {
        model: [
          { key: "←→", label: "NAVIGATION" },
          { key: "↵", label: "SELECT CODE" },
          { key: "R", label: "NEW BREACH" },
          { key: "ESC", label: "CLOSE" }
        ]
        delegate: Row {
          required property var modelData
          spacing: 8

          KeyCap { label: modelData.key }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label
            color: Theme.primary
            font.family: Theme.fontUi
            font.pixelSize: 16
            font.weight: Font.Bold
            font.letterSpacing: 1
          }
        }
      }
    }

    MicroText {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      text: "CUSTOM GLITCHES ON UI MAY APPEAR, BASED ON THIS ANALYSIS.\nDOCUMENT/0/YIJTZLABKETJ3DHXCDQOTCIHWM\nTYPE: CYBERSPACE // " + Theme.os.toUpperCase()
      lineHeight: 1.2
    }
  }

  // ------------------------------------------------------------ feedback

  Rectangle {
    id: flash
    anchors.fill: parent
    color: Theme.primary
    opacity: 0
  }

  NumberAnimation { id: pickFlash; target: flash; property: "opacity"; from: 0.06; to: 0; duration: 180 }

  SequentialAnimation {
    id: resultAnim
    PauseAnimation { duration: 250 }
    NumberAnimation { target: banner; property: "opacity"; from: 0; to: 1; duration: 60 }
    NumberAnimation { target: banner; property: "opacity"; to: 0.3; duration: 50 }
    NumberAnimation { target: banner; property: "opacity"; to: 1; duration: 80 }
  }
}
