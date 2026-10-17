pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live niri state fed by `niri msg --json event-stream`: no polling at all,
// the bar only wakes up when the compositor actually reports a change.
Singleton {
  id: niri

  property var workspaces: []
  property var windows: ({})
  property var focusedWindowId: null
  property bool overview: false
  property var layouts: []
  property int layoutIndex: 0

  readonly property var focusedWorkspace: workspaces.find(w => w.is_focused) || null
  readonly property string focusedOutput: focusedWorkspace ? (focusedWorkspace.output || "") : ""
  readonly property var focusedWindow: focusedWindowId !== null ? (windows[focusedWindowId] || null) : null
  readonly property string layout: layouts.length > layoutIndex ? layouts[layoutIndex] : ""

  function workspacesOn(output) {
    return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx)
  }

  function activeWindowOn(output) {
    const ws = workspaces.find(w => w.output === output && w.is_active)
    if (!ws || ws.active_window_id === null || ws.active_window_id === undefined) return null
    return windows[ws.active_window_id] || null
  }

  function windowCount(workspaceId) {
    let n = 0
    for (const id in windows) if (windows[id].workspace_id === workspaceId) n++
    return n
  }

  // ------------------------------------------------------------ actions

  function action(args) {
    Quickshell.execDetached([Theme.bin("niri"), "msg", "action"].concat(args))
  }

  // the shell's overlays draw over the workspaces: leave the overview first
  function closeOverview() {
    if (overview) action(["close-overview"])
  }

  function focusWorkspace(ws) {
    if (ws.output && ws.output !== focusedOutput)
      Quickshell.execDetached(["sh", "-c", "\"$0\" msg action focus-monitor \"$1\" && \"$0\" msg action focus-workspace \"$2\"", Theme.bin("niri"), ws.output, String(ws.idx)])
    else
      action(["focus-workspace", String(ws.idx)])
  }

  function cycleWorkspace(output, delta) {
    if (output !== focusedOutput) return
    action([delta > 0 ? "focus-workspace-down" : "focus-workspace-up"])
  }

  // ------------------------------------------------------------ events

  function setWorkspaces(list) {
    workspaces = list.slice().sort((a, b) => (a.output || "").localeCompare(b.output || "") || a.idx - b.idx)
  }

  function handle(event) {
    if (event.WorkspacesChanged) {
      setWorkspaces(event.WorkspacesChanged.workspaces)
    } else if (event.WorkspaceActivated) {
      const id = event.WorkspaceActivated.id
      const focused = event.WorkspaceActivated.focused
      const target = workspaces.find(w => w.id === id)
      if (!target) return
      setWorkspaces(workspaces.map(w => {
        const copy = Object.assign({}, w)
        if (w.output === target.output) copy.is_active = w.id === id
        if (focused) copy.is_focused = w.id === id
        return copy
      }))
    } else if (event.WorkspaceActiveWindowChanged) {
      const change = event.WorkspaceActiveWindowChanged
      setWorkspaces(workspaces.map(w => w.id === change.workspace_id ? Object.assign({}, w, { active_window_id: change.active_window_id }) : w))
    } else if (event.WorkspaceUrgencyChanged) {
      const change = event.WorkspaceUrgencyChanged
      setWorkspaces(workspaces.map(w => w.id === change.id ? Object.assign({}, w, { is_urgent: change.urgent }) : w))
    } else if (event.WindowsChanged) {
      const map = {}
      let focus = null
      for (const w of event.WindowsChanged.windows) {
        map[w.id] = w
        if (w.is_focused) focus = w.id
      }
      windows = map
      focusedWindowId = focus
    } else if (event.WindowOpenedOrChanged) {
      const w = event.WindowOpenedOrChanged.window
      const map = Object.assign({}, windows)
      if (w.is_focused)
        for (const id in map) if (map[id].is_focused) map[id] = Object.assign({}, map[id], { is_focused: false })
      map[w.id] = w
      windows = map
      // after the map: a window that opens focused must already be in it
      if (w.is_focused) focusedWindowId = w.id
    } else if (event.WindowClosed) {
      const map = Object.assign({}, windows)
      delete map[event.WindowClosed.id]
      windows = map
      if (focusedWindowId === event.WindowClosed.id) focusedWindowId = null
    } else if (event.WindowFocusChanged) {
      const id = event.WindowFocusChanged.id
      focusedWindowId = id === undefined ? null : id
    } else if (event.WindowUrgencyChanged) {
      const change = event.WindowUrgencyChanged
      if (windows[change.id]) {
        const map = Object.assign({}, windows)
        map[change.id] = Object.assign({}, map[change.id], { is_urgent: change.urgent })
        windows = map
      }
    } else if (event.KeyboardLayoutsChanged) {
      layouts = event.KeyboardLayoutsChanged.keyboard_layouts.names
      layoutIndex = event.KeyboardLayoutsChanged.keyboard_layouts.current_idx
    } else if (event.KeyboardLayoutSwitched) {
      layoutIndex = event.KeyboardLayoutSwitched.idx
    } else if (event.OverviewOpenedOrClosed) {
      overview = event.OverviewOpenedOrClosed.is_open
    }
  }

  Process {
    id: stream
    command: [Theme.bin("niri"), "msg", "--json", "event-stream"]
    running: true
    stdout: SplitParser {
      onRead: (line) => {
        if (line.length === 0) return
        try {
          niri.handle(JSON.parse(line))
        } catch (error) {
          console.warn("cyberdeck: bad niri event: " + error)
        }
      }
    }
    onExited: restart.start()
  }

  // niri restarts (or a config reload) can drop the stream: reconnect
  Timer {
    id: restart
    interval: 1500
    onTriggered: stream.running = true
  }
}
