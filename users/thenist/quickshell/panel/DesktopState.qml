import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root
  property real brightness: -1
  property string network: "Checking network…"
  property string error: ""
  property int pendingBrightness: -1
  signal brightnessAdjusted(real value)

  function refreshBrightness() {
    if (!brightnessRead.running && !brightnessWrite.running)
      brightnessRead.running = true;
  }

  function refresh() {
    refreshBrightness();
    if (!networkRead.running)
      networkRead.running = true;
  }

  function setBrightness(value) {
    pendingBrightness = Math.max(1, Math.min(100, Math.round(value)));
    writeDelay.restart();
  }

  Process {
    id: brightnessRead
    command: ["brightnessctl", "--class=backlight", "--machine-readable", "info"]
    stdout: StdioCollector {
      onStreamFinished: {
        const fields = text.trim().split("\n")[0].split(",");
        const value = fields.length >= 5 ? Number(fields[2]) / Number(fields[4]) * 100 : NaN;
        if (!isFinite(value)) {
          root.brightness = -1;
          return;
        }
        const previous = root.brightness;
        root.brightness = value;
        if (previous >= 0 && Math.abs(previous - value) > 0.05)
          root.brightnessAdjusted(value);
      }
    }
  }

  Timer {
    id: writeDelay
    interval: 80
    onTriggered: {
      if (brightnessWrite.running) {
        restart();
        return;
      }
      brightnessWrite.command = ["brightnessctl", "--class=backlight", "--min-value=1", "set", root.pendingBrightness + "%"];
      root.pendingBrightness = -1;
      brightnessWrite.running = true;
    }
  }

  Process {
    id: brightnessWrite
    onExited: (code, status) => {
      root.error = code === 0 ? "" : "Could not change brightness";
      root.refreshBrightness();
    }
  }

  Process {
    id: networkRead
    command: ["nmcli", "--terse", "--fields", "STATE,CONNECTIVITY", "general"]
    environment: ({
        LC_ALL: "C"
      })
    stdout: StdioCollector {
      onStreamFinished: {
        const fields = text.trim().split(":");
        if (fields[1] === "full")
          root.network = "Connected · Internet available";
        else if (fields[1] === "portal")
          root.network = "Sign-in required";
        else if (fields[0].startsWith("connected"))
          root.network = "Connected · Limited connectivity";
        else if (fields[0] === "connecting")
          root.network = "Connecting…";
        else
          root.network = "Disconnected";
      }
    }
    onExited: (code, status) => {
      if (code !== 0)
        root.network = "Network status unavailable";
    }
  }

  Timer {
    interval: 3000
    running: root.brightness >= 0
    repeat: true
    onTriggered: root.refreshBrightness()
  }
  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }
  Component.onCompleted: refresh()
}
