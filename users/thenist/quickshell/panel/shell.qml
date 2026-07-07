//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets

ShellRoot {
  id: root

  property date now: new Date()

  function run(command) {
    Quickshell.execDetached(["sh", "-c", command]);
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
      implicitHeight: 44
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
      exclusiveZone: 52

      Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#11131add"
        border.width: 1
        border.color: "#2f3344"

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          ActionPill {
            label: Quickshell.env("XDG_CURRENT_DESKTOP") || "driftwm"
            emphasized: true
            onClicked: root.run("fuzzel")
          }

          ActionPill {
            label: "terminal"
            onClicked: root.run("foot")
          }
        }

        Text {
          anchors.centerIn: parent
          text: Qt.formatDateTime(root.now, "ddd MMM d  HH:mm")
          color: "#cad3f5"
          font.pixelSize: 14
          font.weight: Font.DemiBold
        }

        Row {
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 10

          Repeater {
            model: SystemTray.items

            MouseArea {
              id: trayItem

              required property var modelData

              width: 24
              height: 24
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
              cursorShape: Qt.PointingHandCursor

              IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: trayItem.modelData.icon
              }

              function openMenu() {
                const pos = trayItem.mapToItem(panel.contentItem, 0, trayItem.height);
                trayItem.modelData.display(panel, Math.round(pos.x), Math.round(pos.y));
              }

              onPressed: function(mouse) {
                if (trayItem.modelData.hasMenu && (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu)) {
                  mouse.accepted = true;
                  trayItem.openMenu();
                }
              }

              onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton && !trayItem.modelData.onlyMenu) {
                  trayItem.modelData.activate();
                } else if (mouse.button === Qt.MiddleButton) {
                  trayItem.modelData.secondaryActivate();
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
            label: "lock"
            onClicked: root.run("quickshell -n -p ~/.config/quickshell/lock/shell.qml")
          }

          ActionPill {
            id: powerButton

            label: "power"
            onClicked: powerMenu.visible = !powerMenu.visible
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
            const pos = powerButton.QsWindow.contentItem.mapFromItem(
              powerButton,
              powerButton.width - powerMenu.width,
              powerButton.height + 8
            );

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
      font.weight: Font.DemiBold
    }
  }

  component ActionPill: Rectangle {
    id: pill

    property string label: ""
    property bool emphasized: false
    signal clicked()

    width: text.implicitWidth + 22
    height: 28
    radius: 14
    color: emphasized ? "#8aadf4" : "#181b25"

    Text {
      id: text
      anchors.centerIn: parent
      text: pill.label
      color: pill.emphasized ? "#11131a" : "#cad3f5"
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: pill.clicked()
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
