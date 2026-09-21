import QtQuick
import Quickshell
import Quickshell.Io

// One event connection for all monitors; commands use a separate socket.
Scope {
  id: root
  property var workspaces: []
  property double lastScroll: 0

  function receive(line) {
    let event;
    try {
      event = JSON.parse(line);
    } catch (_) {
      return;
    }
    if (event.WorkspacesChanged) {
      workspaces = event.WorkspacesChanged.workspaces;
    } else if (event.WorkspaceActivated) {
      const change = event.WorkspaceActivated;
      const target = workspaces.find(w => w.id === change.id);
      if (!target)
        return;
      workspaces = workspaces.map(w => Object.assign({}, w, {
          is_active: w.output === target.output ? w.id === change.id : w.is_active,
          is_focused: change.focused ? w.id === change.id : w.is_focused
        }));
    } else if (event.WorkspaceActiveWindowChanged) {
      const change = event.WorkspaceActiveWindowChanged;
      workspaces = workspaces.map(w => w.id === change.workspace_id ? Object.assign({}, w, {
          active_window_id: change.active_window_id
        }) : w);
    } else if (event.WorkspaceUrgencyChanged) {
      const change = event.WorkspaceUrgencyChanged;
      workspaces = workspaces.map(w => w.id === change.id ? Object.assign({}, w, {
          is_urgent: change.urgent
        }) : w);
    }
  }

  function forOutput(output) {
    return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx);
  }

  function focus(id) {
    if (command.connected)
      return;
    command.request = JSON.stringify({
      Action: {
        FocusWorkspace: {
          reference: {
            Id: id
          }
        }
      }
    });
    command.connected = true;
  }

  function step(output, direction) {
    const now = Date.now();
    if (now - lastScroll < 150)
      return;
    lastScroll = now;
    const list = forOutput(output);
    const index = list.findIndex(w => w.is_active);
    const next = Math.max(0, Math.min(list.length - 1, index + direction));
    if (list[next])
      focus(list[next].id);
  }

  Socket {
    id: events
    path: Quickshell.env("NIRI_SOCKET")
    connected: path.length > 0
    onConnectedChanged: {
      if (connected) {
        write('"EventStream"\n');
        flush();
      } else {
        root.workspaces = [];
      }
    }
    parser: SplitParser {
      onRead: line => root.receive(line)
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: !events.connected && events.path.length > 0
    onTriggered: events.connected = true
  }

  Socket {
    id: command
    property string request: ""
    path: Quickshell.env("NIRI_SOCKET")
    onConnectedChanged: {
      if (connected) {
        write(request + "\n");
        flush();
      }
    }
    parser: SplitParser {
      onRead: line => {
        if (JSON.parse(line).Err)
          console.warn("Niri action failed:", line);
        command.connected = false;
      }
    }
  }
}
