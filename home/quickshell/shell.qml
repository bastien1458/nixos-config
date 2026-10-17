import QtQuick
import Quickshell
import Quickshell.Io

// Cyberdeck: a Cyberpunk 2077 desktop shell for niri.
ShellRoot {
  id: shell

  Variants {
    model: Quickshell.screens
    Bar {}
  }

  Quickhack { id: quickhack }
  ControlCenter {}
  OsMenu {}
  WallMenu {}
  SettingsMenu {}
  Breach {}
  NotificationPopups {}
  Holocall {}
  Osd {}
  Reboot {}
  Boot {}

  Connections {
    target: Hud
    function onQuickhackRequested() { quickhack.toggle() }
    function onCaffeineChanged() {
      // no idle daemon, no lock and no monitor sleep while the adrenaline runs
      Quickshell.execDetached(["systemctl", "--user", Hud.caffeine ? "stop" : "start", "cyberdeck-idle.service"])
    }
  }

  // singletons are lazy: touch the ones that must exist from the start
  Component.onCompleted: {
    Notifs.count
    Lock.locked
    Blackwall.integrity
    Sounds.loop
    Settings.barHeight
  }

  IpcHandler {
    target: "quickhack"
    function toggle(): void { quickhack.toggle() }
    function open(): void { quickhack.show() }
    function close(): void { quickhack.close() }
  }

  IpcHandler {
    target: "cc"
    function toggle(): void { Hud.toggleCc("") }
    function close(): void { Hud.ccOpen = false }
  }

  IpcHandler {
    target: "os"
    function open(): void { Hud.toggleOs("") }
    function install(id: string): void { Theme.switchTo(id) }
    function current(): string { return Theme.os }
  }

  IpcHandler {
    target: "wallpaper"
    function open(): void { Hud.toggleWall("") }
    function set(path: string): void { Theme.setWallpaper(path) }
    function current(): string { return Theme.wallpaper }
  }

  IpcHandler {
    target: "settings"
    function toggle(): void { Hud.toggleSettings("") }
    function open(): void { if (!Hud.settingsOpen) Hud.toggleSettings("") }
    function close(): void { Hud.settingsOpen = false }
  }

  IpcHandler {
    target: "breach"
    function open(): void { Hud.openBreach("") }
  }

  IpcHandler {
    target: "sounds"
    function rescan(): void { Sounds.rescan() }
  }

  IpcHandler {
    target: "call"
    // quickshell -c cyberdeck ipc call call test "Jackie Welles"
    function test(name: string): void { Calls.test(name) }
    function stop(): void { Calls.stop() }
  }

  IpcHandler {
    target: "lock"
    function lock(): void { Lock.lock() }
    function isLocked(): bool { return Lock.locked }
  }

  IpcHandler {
    target: "blackwall"
    function whisper(): void { Blackwall.speak("") }
  }

  IpcHandler {
    target: "theme"
    function reload(): void { Theme.reload() }
  }

  IpcHandler {
    target: "dnd"
    function toggle(): void { Hud.dnd = !Hud.dnd }
  }
}
