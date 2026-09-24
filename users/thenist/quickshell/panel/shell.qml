//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import "i18n"

ShellRoot {
  id: root

  property date now: new Date()
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var sinkAudio: sink && sink.ready ? sink.audio : null

  Niri {
    id: niri
  }
  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  DesktopState {
    id: systemState
    onBrightnessAdjusted: value => root.showFeedback(Tr.tr("Brightness  %1%").arg(Math.round(value)), value / 100)
  }

  IpcHandler {
    target: "desktop"
    function refreshBrightness(): void {
      systemState.refreshBrightness();
    }
    function power(): void {
      root.togglePower();
    }
    function launcher(): void {
      root.toggleLauncher();
    }
  }
  property string feedbackLabel: ""
  property real feedbackLevel: 0
  property string feedbackOutput: ""
  property bool feedbackVisible: false
  property bool audioInitialized: false
  // Screen name the power menu is open on; empty while it is closed.
  property string powerOutput: ""
  // Screen name the launcher is open on; empty while it is closed.
  property string launcherOutput: ""

  readonly property bool powerOpen: powerOutput.length > 0
  readonly property bool launcherOpen: launcherOutput.length > 0

  // Screen that currently has the focused workspace, falling back to the first
  // screen so shell-triggered popups always land somewhere.
  function focusedOutput() {
    const focused = niri.workspaces.find(w => w.is_focused);
    return focused ? focused.output : (Quickshell.screens.length ? Quickshell.screens[0].name : "");
  }

  function openPower(output) {
    closeLauncher();
    powerOutput = output && output.length > 0 ? output : root.focusedOutput();
  }

  function closePower() {
    powerOutput = "";
  }

  function togglePower() {
    if (root.powerOpen)
      root.closePower();
    else
      root.openPower("");
  }

  function openLauncher(output) {
    launcherOutput = output && output.length > 0 ? output : root.focusedOutput();
  }

  function closeLauncher() {
    launcherOutput = "";
  }

  function toggleLauncher() {
    if (root.launcherOpen)
      root.closeLauncher();
    else
      root.openLauncher("");
  }

  function showFeedback(label, level) {
    feedbackLabel = label;
    feedbackLevel = level;
    feedbackOutput = root.focusedOutput();
    feedbackVisible = true;
    feedbackTimer.restart();
  }

  function audioChanged() {
    if (!audioInitialized || !sinkAudio)
      return;
    showFeedback(sinkAudio.muted ? Tr.tr("Sound muted") : Tr.tr("Volume  %1%").arg(Math.round(sinkAudio.volume * 100)), sinkAudio.muted ? 0 : sinkAudio.volume);
  }

  onSinkAudioChanged: {
    audioInitialized = false;
    audioWarmup.restart();
  }
  Timer {
    id: audioWarmup
    interval: 300
    running: true
    onTriggered: root.audioInitialized = !!root.sinkAudio
  }
  Timer {
    id: feedbackTimer
    interval: 1600
    onTriggered: root.feedbackVisible = false
  }
  Connections {
    target: root.sinkAudio
    function onVolumeChanged() {
      root.audioChanged();
    }
    function onMutedChanged() {
      root.audioChanged();
    }
  }

  function setVolume(value) {
    if (sinkAudio)
      sinkAudio.volume = Math.max(0, Math.min(1, value));
  }

  function toggleMute() {
    if (sinkAudio)
      sinkAudio.muted = !sinkAudio.muted;
  }

  function run(command) {
    Quickshell.execDetached(["sh", "-c", command]);
  }

  // Desktop entries carry their own argv, so they go straight to execDetached
  // instead of through a shell. Entries that set Path= are rare, so only those
  // get a shell that chdirs first, with the argv passed positionally so it is
  // never re-interpreted. execDetached's object overload is not an option here:
  // QML only converts an argument written as a literal into a ProcessContext,
  // and the argv is only known at runtime.
  function launch(command, workingDirectory) {
    if (workingDirectory && workingDirectory.length > 0)
      Quickshell.execDetached(["sh", "-c", "cd \"$1\" && exec \"$@\"", "sh", workingDirectory].concat(command));
    else
      Quickshell.execDetached(command);
  }

  ScriptModel {
    id: audioSinkModel

    values: Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)
  }

  function batteries() {
    const devices = UPower.devices.values;
    const batteries = [];

    for (let i = 0; i < devices.length; i++) {
      const device = devices[i];
      if (device && device.ready && device.isPresent && device.type === UPowerDeviceType.Battery && device.powerSupply) {
        batteries.push(device);
      }
    }

    return batteries;
  }

  function hasBattery() {
    return root.batteries().length > 0;
  }

  function batteryPercent() {
    const batteries = root.batteries();
    let charge = 0;
    let capacity = 0;

    for (let i = 0; i < batteries.length; i++) {
      const battery = batteries[i];

      if (battery.energyCapacity > 0) {
        charge += Math.max(0, battery.energy);
        capacity += battery.energyCapacity;
      } else {
        charge += Math.max(0, battery.percentage);
        capacity += 100;
      }
    }

    return capacity > 0 ? Math.round(charge / capacity * 100) : 0;
  }

  function batteryCharging() {
    if (UPower.onBattery) {
      return false;
    }

    const batteries = root.batteries();

    for (let i = 0; i < batteries.length; i++) {
      const state = batteries[i].state;
      if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge) {
        return true;
      }
    }

    return false;
  }

  function batteryFull() {
    const batteries = root.batteries();
    if (batteries.length === 0) {
      return false;
    }

    for (let i = 0; i < batteries.length; i++) {
      if (batteries[i].state !== UPowerDeviceState.FullyCharged) {
        return false;
      }
    }

    return true;
  }

  function batteryLabel() {
    if (!root.hasBattery()) {
      return "";
    }

    if (root.batteryCharging()) {
      return Tr.tr("chg %1%").arg(root.batteryPercent());
    }

    if (root.batteryFull()) {
      return Tr.tr("full");
    }

    return Tr.tr("bat %1%").arg(root.batteryPercent());
  }

  function batteryColor() {
    if (!root.hasBattery()) {
      return "#181b25";
    }

    if (root.batteryCharging()) {
      return "#263026";
    }

    return root.batteryPercent() <= 15 ? "#3a2028" : "#181b25";
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property var modelData

      screen: modelData
      color: "transparent"
      implicitHeight: 38
      anchors {
        top: true
        left: true
        right: true
      }
      margins {
        top: 8
        left: 8
        right: 8
      }
      exclusiveZone: 46

      // Control center, power menu and launcher never show at the same time.
      function toggleControls() {
        controls.visible = !controls.visible;
        if (controls.visible) {
          root.closePower();
          root.closeLauncher();
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#dd11131a"
        border.width: 1
        border.color: "#2f3344"

        Row {
          id: leftRow
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          ActionPill {
            label: "󱄅"
            iconFont: true
            emphasized: root.launcherOpen && root.launcherOutput === panel.screen.name
            onClicked: root.toggleLauncher()
          }

          Flickable {
            id: workspaceStrip
            width: Math.max(0, Math.min(workspaceRow.width, panel.width - rightRow.width - 120))
            height: 28
            contentWidth: workspaceRow.width
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            function revealActive() {
              const list = niri.forOutput(panel.screen.name);
              const index = list.findIndex(w => w.is_active);
              const item = workspaceRepeater.itemAt(index);
              if (!item)
                return;
              if (item.x < contentX)
                contentX = item.x;
              else if (item.x + item.width > contentX + width)
                contentX = item.x + item.width - width;
              contentX = Math.max(0, Math.min(contentX, Math.max(0, contentWidth - width)));
            }
            onWidthChanged: Qt.callLater(revealActive)
            Connections {
              target: niri
              function onWorkspacesChanged() {
                Qt.callLater(workspaceStrip.revealActive);
              }
            }

            Row {
              id: workspaceRow
              spacing: 4
              Repeater {
                id: workspaceRepeater
                model: niri.forOutput(panel.screen.name)
                ActionPill {
                  required property var modelData
                  label: String(modelData.idx)
                  emphasized: modelData.is_active
                  urgent: modelData.is_urgent || false
                  dimmed: !modelData.is_active && modelData.active_window_id === null
                  onClicked: niri.focus(modelData.id)
                  onScrolled: delta => niri.step(panel.screen.name, delta > 0 ? -1 : 1)
                }
              }
            }
          }
        }

        Text {
          id: clockText
          anchors.verticalCenter: parent.verticalCenter
          readonly property real freeLeft: leftRow.x + leftRow.width + 12
          readonly property real freeRight: rightRow.x - 12
          x: Math.max(freeLeft, Math.min((parent.width - width) / 2, freeRight - width))
          visible: freeRight - freeLeft >= implicitWidth
          text: Qt.locale().toString(root.now, Tr.tr(panel.width < 850 ? "HH:mm" : "ddd d MMM  HH:mm"))
          color: "#cad3f5"
          font.family: "Adwaita Sans"
          font.pixelSize: 13
          font.weight: Font.DemiBold
        }

        Row {
          id: rightRow
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          Flickable {
            width: Math.min(trayRow.width, panel.width < 700 ? 48 : 144)
            height: 28
            contentWidth: trayRow.width
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Row {
              id: trayRow
              Repeater {
                model: SystemTray.items

                MouseArea {
                  id: trayItem

                  required property var modelData

                  width: 24
                  height: 24
                  acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                  cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true

                  Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: trayItem.containsMouse ? "#242838" : "transparent"
                  }

                  IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: trayItem.modelData.icon
                  }

                  function openMenu() {
                    const pos = trayItem.mapToItem(panel.contentItem, 0, trayItem.height);
                    trayItem.modelData.display(panel, Math.round(pos.x), Math.round(pos.y));
                  }

                  onPressed: function (mouse) {
                    if (trayItem.modelData.hasMenu && (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu)) {
                      mouse.accepted = true;
                      trayItem.openMenu();
                    }
                  }

                  onClicked: function (mouse) {
                    if (mouse.button === Qt.LeftButton && !trayItem.modelData.onlyMenu) {
                      trayItem.modelData.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                      trayItem.modelData.secondaryActivate();
                    }
                  }
                }
              }
            }
          }

          StatusPill {
            visible: root.hasBattery()
            label: root.batteryLabel()
            color: root.batteryColor()
          }

          ActionPill {
            id: audioButton

            label: !root.sinkAudio ? "󰖁 —" : root.sinkAudio.muted ? "󰖁 " + Tr.tr("muted") : "󰕾 " + Math.round(root.sinkAudio.volume * 100) + "%"
            onMiddleClicked: root.toggleMute()
            onScrolled: delta => {
              if (root.sinkAudio)
                root.setVolume(root.sinkAudio.volume + (delta > 0 ? 0.05 : -0.05));
            }
            onClicked: panel.toggleControls()
          }

          ActionPill {
            id: controlsButton
            label: "󰒓"
            iconFont: true
            emphasized: controls.visible
            onClicked: panel.toggleControls()
          }

          ActionPill {
            id: powerButton
            label: "󰐥"
            iconFont: true
            emphasized: root.powerOpen && root.powerOutput === panel.screen.name
            onClicked: {
              controls.visible = false;
              root.openPower(panel.screen.name);
            }
          }
        }
      }

      ControlCenter {
        id: controls
        desktop: systemState
        audio: root.sinkAudio
        outputs: audioSinkModel
        onVolumeRequested: value => root.setVolume(value)
        onMuteRequested: root.toggleMute()
        onCommandRequested: command => root.run(command)
        anchor {
          window: panel
          adjustment: PopupAdjustment.Slide
          gravity: Edges.Bottom | Edges.Right
          rect.x: panel.width - controls.width - 8
          rect.y: panel.height + 8
        }
      }

      PowerMenu {
        id: power
        opened: root.powerOpen && root.powerOutput === panel.screen.name
        onCloseRequested: root.closePower()
        onCommandRequested: command => root.run(command)
      }

      Launcher {
        id: launcher
        opened: root.launcherOpen && root.launcherOutput === panel.screen.name
        onOpenedChanged: {
          if (opened) {
            controls.visible = false;
            root.closePower();
          }
        }
        onCloseRequested: root.closeLauncher()
        onLaunchRequested: (command, workingDirectory) => root.launch(command, workingDirectory)
      }

      Feedback {
        screen: panel.screen
        shown: root.feedbackVisible && root.feedbackOutput === panel.screen.name && !controls.visible && !power.opened && !launcher.opened
        label: root.feedbackLabel
        level: root.feedbackLevel
      }
    }
  }

  component StatusPill: Rectangle {
    id: pill

    property string label: ""

    width: text.implicitWidth + 22
    height: 28
    radius: 14

    Text {
      id: text

      anchors.centerIn: parent
      text: pill.label
      color: "#cad3f5"
      font.pixelSize: 13
      font.family: "Adwaita Sans"
      font.weight: Font.DemiBold
    }
  }

  component ActionPill: Rectangle {
    id: pill

    property string label: ""
    property bool emphasized: false
    property bool urgent: false
    property bool dimmed: false
    property bool iconFont: false
    property int maximumWidth: 10000
    signal clicked
    signal middleClicked
    signal scrolled(real delta)

    width: Math.min(text.implicitWidth + 22, maximumWidth)
    height: 28
    radius: 8
    color: emphasized ? "#8aadf4" : mouse.containsMouse ? "#242838" : "transparent"
    border.width: urgent ? 1 : 0
    border.color: "#ed8796"
    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }
    Text {
      id: text

      anchors.centerIn: parent
      width: parent.width - 22
      text: pill.label
      color: pill.emphasized ? "#11131a" : pill.dimmed ? "#6e738d" : "#cad3f5"
      elide: Text.ElideRight
      font.pixelSize: 13
      font.family: pill.iconFont ? "JetBrainsMono Nerd Font" : "Adwaita Sans"
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      cursorShape: Qt.PointingHandCursor
      onClicked: event => event.button === Qt.MiddleButton ? pill.middleClicked() : pill.clicked()
      onWheel: event => {
        if (event.angleDelta.y !== 0)
          pill.scrolled(event.angleDelta.y);
      }
    }
  }
}
