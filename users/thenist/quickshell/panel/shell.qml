//@ pragma UseQApplication

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets

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

  function audioDeviceName(node) {
    if (!node) {
      return "unavailable";
    }

    return node.description || node.nickname || node.name || "unnamed output";
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
      return "chg " + root.batteryPercent() + "%";
    }

    if (root.batteryFull()) {
      return "full";
    }

    return "bat " + root.batteryPercent() + "%";
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

      Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#11131add"
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
            tooltip: "Applications · Mod+D"
            onClicked: root.run("fuzzel")
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
                  tooltip: modelData.name || "Workspace " + modelData.idx
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
          text: Qt.formatDateTime(root.now, panel.width < 850 ? "HH:mm" : "ddd d MMM  HH:mm")
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
                  ToolTip.visible: containsMouse
                  ToolTip.delay: 600
                  ToolTip.text: modelData.tooltipTitle || modelData.title || "Tray item"

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

            label: !root.sinkAudio ? "󰖁 —" : root.sinkAudio.muted ? "󰖁 muted" : "󰕾 " + Math.round(root.sinkAudio.volume * 100) + "%"
            tooltip: root.audioDeviceName(root.sink) + "\nScroll: volume · Middle-click: mute"
            onMiddleClicked: root.toggleMute()
            onScrolled: delta => {
              if (root.sinkAudio)
                root.setVolume(root.sinkAudio.volume + (delta > 0 ? 0.05 : -0.05));
            }
            onClicked: {
              powerMenu.visible = false;
              audioMenu.visible = !audioMenu.visible;
            }
          }

          ActionPill {
            visible: panel.width >= 700
            label: "󰌾"
            iconFont: true
            tooltip: "Lock · Mod+L"
            onClicked: root.run("quickshell -n -p ~/.config/quickshell/lock/shell.qml")
          }

          ActionPill {
            id: powerButton

            label: "󰐥"
            iconFont: true
            tooltip: "Session and power"
            onClicked: {
              audioMenu.visible = false;
              powerMenu.visible = !powerMenu.visible;
            }
          }
        }
      }

      PopupWindow {
        id: audioMenu

        color: "transparent"
        visible: false
        grabFocus: true
        implicitWidth: audioMenuContent.implicitWidth
        implicitHeight: audioMenuContent.implicitHeight

        anchor {
          window: audioButton.QsWindow.window
          adjustment: PopupAdjustment.Slide
          gravity: Edges.Bottom | Edges.Right

          onAnchoring: {
            const pos = audioButton.QsWindow.contentItem.mapFromItem(audioButton, audioButton.width - audioMenu.width, audioButton.height + 8);

            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
          }
        }

        Rectangle {
          id: audioMenuContent

          implicitWidth: 320
          implicitHeight: audioMenuColumn.implicitHeight + 14
          radius: 14
          color: "#11131af2"
          border.width: 1
          border.color: "#2f3344"

          Column {
            id: audioMenuColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
              width: parent.width - 28
              x: 14
              text: root.audioDeviceName(root.sink)
              elide: Text.ElideRight
              color: "#cad3f5"
              font.family: "Adwaita Sans"
              font.pixelSize: 13
              height: 30
              verticalAlignment: Text.AlignVCenter
            }

            Row {
              x: 14
              spacing: 10
              ActionPill {
                label: root.sinkAudio && root.sinkAudio.muted ? "Unmute" : "Mute"
                tooltip: "Toggle output mute"
                onClicked: root.toggleMute()
              }
              Slider {
                width: 150
                height: 28
                from: 0
                to: 1
                stepSize: 0.01
                enabled: !!root.sinkAudio
                value: root.sinkAudio ? root.sinkAudio.volume : 0
                onMoved: root.setVolume(value)
                palette.highlight: "#8aadf4"
                palette.button: "#cad3f5"
              }
              Text {
                text: root.sinkAudio ? Math.round(root.sinkAudio.volume * 100) + "%" : "—"
                color: "#cad3f5"
                font.family: "Adwaita Sans"
                font.pixelSize: 12
                height: 28
                verticalAlignment: Text.AlignVCenter
              }
            }

            Text {
              width: parent.width
              height: 28
              leftPadding: 14
              text: "audio output"
              color: "#8aadf4"
              font.family: "Adwaita Sans"
              font.pixelSize: 12
              font.weight: Font.DemiBold
              verticalAlignment: Text.AlignVCenter
            }

            Repeater {
              model: audioSinkModel

              AudioMenuItem {
                required property var modelData

                audioNode: modelData
                menu: audioMenu
              }
            }

            Text {
              visible: audioSinkModel.values.length === 0
              width: parent.width
              height: visible ? 32 : 0
              leftPadding: 14
              text: "no audio outputs available"
              color: "#6e738d"
              font.family: "Adwaita Sans"
              font.pixelSize: 13
              verticalAlignment: Text.AlignVCenter
            }
          }
        }
      }

      PopupWindow {
        id: powerMenu

        color: "transparent"
        visible: false
        grabFocus: true
        implicitWidth: powerMenuContent.implicitWidth
        implicitHeight: powerMenuContent.implicitHeight

        anchor {
          window: powerButton.QsWindow.window
          adjustment: PopupAdjustment.Slide
          gravity: Edges.Bottom | Edges.Right

          onAnchoring: {
            const pos = powerButton.QsWindow.contentItem.mapFromItem(powerButton, powerButton.width - powerMenu.width, powerButton.height + 8);

            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
          }
        }

        Rectangle {
          id: powerMenuContent

          implicitWidth: 132
          implicitHeight: powerMenuColumn.implicitHeight + 14
          radius: 14
          color: "#11131af2"
          border.width: 1
          border.color: "#2f3344"

          Column {
            id: powerMenuColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            PowerMenuItem {
              label: "lock"
              command: "quickshell -n -p ~/.config/quickshell/lock/shell.qml"
              menu: powerMenu
            }

            PowerMenuItem {
              label: "suspend"
              command: "systemctl suspend"
              menu: powerMenu
            }

            PowerMenuItem {
              label: "reboot"
              command: "systemctl reboot"
              menu: powerMenu
            }

            PowerMenuItem {
              label: "shutdown"
              command: "systemctl poweroff"
              menu: powerMenu
              destructive: true
            }
          }
        }
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
    property string tooltip: ""
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
    ToolTip.visible: mouse.containsMouse && tooltip.length > 0
    ToolTip.text: tooltip
    ToolTip.delay: 600

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

  component AudioMenuItem: Rectangle {
    id: item

    required property var audioNode
    required property var menu
    property bool active: Pipewire.defaultAudioSink === audioNode

    width: parent ? parent.width : 0
    height: 34
    color: active || mouse.containsMouse ? "#242838" : "transparent"

    Rectangle {
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      width: 7
      height: 7
      radius: 4
      color: item.active ? "#8aadf4" : "#3b4055"
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 31
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      text: root.audioDeviceName(item.audioNode)
      font.family: "Adwaita Sans"
      color: item.active ? "#8aadf4" : "#cad3f5"
      elide: Text.ElideRight
      font.pixelSize: 13
      font.weight: item.active ? Font.DemiBold : Font.Medium
    }

    MouseArea {
      id: mouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        Pipewire.preferredDefaultAudioSink = item.audioNode;
        item.menu.visible = false;
      }
    }
  }

  component PowerMenuItem: Rectangle {
    id: item

    required property string label
    required property string command
    required property var menu
    property bool destructive: false

    width: parent ? parent.width : 0
    height: 30
    color: mouse.containsMouse ? "#242838" : "transparent"

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      text: item.label
      font.family: "Adwaita Sans"
      color: item.destructive ? "#ed8796" : "#cad3f5"
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }

    MouseArea {
      id: mouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        item.menu.visible = false;
        root.run(item.command);
      }
    }
  }
}
