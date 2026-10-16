import QtQuick

// Text that "decrypts" from random glyphs every time its source changes.
Text {
  id: decoder

  property string source: ""
  property real progress: 1
  property int duration: 320
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

  NumberAnimation {
    id: decodeAnim
    target: decoder
    property: "progress"
    from: 0
    to: 1
    duration: decoder.duration
  }
}
