import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "i18n"

// Session power menu. Power actions deliberately live behind this second-level
// dialog (KDE leave screen / Windows XP "Turn off computer" style) instead of
// sitting in the control center. One overlay per output; the panel decides
// which screen shows it and runs the chosen command.
PanelWindow {
  id: menu

  required property bool opened
  signal closeRequested
  signal commandRequested(string command)

  // Empty while the action grid is shown, otherwise the action that is waiting
  // for confirmation ("reboot" / "poweroff").
  property string pending: ""
  property int highlighted: 0
  property real reveal: 0

  readonly property var actions: [
    {
      icon: "󰌾",
      label: Tr.tr("Lock"),
      accent: "#c6a0f6",
      command: "quickshell -n -p ~/.config/quickshell/lock/shell.qml"
    },
    {
      icon: "󰤄",
      label: Tr.tr("Suspend"),
      accent: "#8aadf4",
      command: "systemctl suspend"
    },
    {
      icon: "󰜉",
      label: Tr.tr("Restart"),
      accent: "#eed49f",
      command: "systemctl reboot",
      confirm: "reboot"
    },
    {
      icon: "󰐥",
      label: Tr.tr("Shut down"),
      accent: "#ed8796",
      command: "systemctl poweroff",
      confirm: "poweroff"
    }
  ]
  readonly property var pendingAction: menu.actions.find(action => action.confirm === menu.pending)

  color: "transparent"
  visible: opened
  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  onOpenedChanged: {
    if (opened) {
      pending = "";
      highlighted = 0;
      reveal = 1;
      input.forceActiveFocus();
    } else {
      reveal = 0;
    }
  }

  function move(delta) {
    highlighted = Math.max(0, Math.min(menu.actions.length - 1, menu.highlighted + delta));
  }

  function activate(index) {
    const action = menu.actions[index];
    if (!action)
      return;
    if (action.confirm) {
      menu.pending = action.confirm;
      return;
    }
    menu.closeRequested();
    menu.commandRequested(action.command);
  }

  function confirm() {
    const action = menu.pendingAction;
    if (!action)
      return;
    menu.closeRequested();
    menu.commandRequested(action.command);
  }

  Item {
    id: input
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: menu.closeRequested()
    Keys.onReturnPressed: menu.pending.length > 0 ? menu.confirm() : menu.activate(menu.highlighted)
    Keys.onEnterPressed: menu.pending.length > 0 ? menu.confirm() : menu.activate(menu.highlighted)
    Keys.onLeftPressed: menu.move(-1)
    Keys.onRightPressed: menu.move(1)
    Keys.onUpPressed: menu.move(-2)
    Keys.onDownPressed: menu.move(2)

    // Dim the desktop; clicks on the scrim cancel.
    Rectangle {
      anchors.fill: parent
      color: "#cc0b0d12"
      MouseArea {
        anchors.fill: parent
        onClicked: menu.closeRequested()
      }
    }

    Rectangle {
      id: dialog

      anchors.centerIn: parent
      width: 352
      implicitHeight: layout.implicitHeight + 44
      radius: 18
      // Qt parses 8-digit hex as #AARRGGBB, so alpha comes first.
      gradient: Gradient {
        GradientStop {
          position: 0.0
          color: "#f71a1e2b"
        }
        GradientStop {
          position: 1.0
          color: "#f712141c"
        }
      }
      border.width: 1
      border.color: "#2f3344"
      opacity: menu.reveal
      scale: 0.97 + 0.03 * menu.reveal
      Behavior on opacity {
        NumberAnimation {
          duration: 150
          easing.type: Easing.OutCubic
        }
      }
      Behavior on scale {
        NumberAnimation {
          duration: 170
          easing.type: Easing.OutCubic
        }
      }

      // Swallow clicks on the card so only the scrim cancels.
      MouseArea {
        anchors.fill: parent
      }

      Rectangle {
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
        }
        height: 3
        topLeftRadius: dialog.radius
        topRightRadius: dialog.radius
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop {
            position: 0.0
            color: "#8aadf4"
          }
          GradientStop {
            position: 0.5
            color: "#c6a0f6"
          }
          GradientStop {
            position: 1.0
            color: "#ed8796"
          }
        }
      }

      ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        RowLayout {
          Layout.fillWidth: true
          spacing: 10
          Text {
            text: "󰐥"
            color: "#ed8796"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
          }
          Text {
            text: Tr.tr("Power")
            color: "#cad3f5"
            font.family: "Adwaita Sans"
            font.pixelSize: 17
            font.weight: Font.DemiBold
            Layout.fillWidth: true
          }
          Text {
            text: Tr.tr("Esc cancels")
            color: "#6e738d"
            font.family: "Adwaita Sans"
            font.pixelSize: 11
          }
        }

        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: 10
          columnSpacing: 10
          visible: menu.pending.length === 0

          Repeater {
            model: menu.actions

            PowerTile {
              required property int index

              action: menu.actions[index]
              highlighted: menu.highlighted === index
              onHoveredChanged: {
                if (hovered)
                  menu.highlighted = index;
              }
              onActivated: menu.activate(index)
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 14
          visible: menu.pending.length > 0

          Text {
            Layout.fillWidth: true
            text: menu.pending === "reboot" ? Tr.tr("Confirm restart") : Tr.tr("Confirm shutdown")
            color: "#cad3f5"
            font.family: "Adwaita Sans"
            font.pixelSize: 16
            font.weight: Font.DemiBold
          }
          Text {
            Layout.fillWidth: true
            text: Tr.tr("Unsaved work will be lost.")
            color: "#6e738d"
            font.family: "Adwaita Sans"
            font.pixelSize: 12
            wrapMode: Text.Wrap
          }
          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            PowerButton {
              Layout.fillWidth: true
              text: Tr.tr("Cancel")
              onClicked: menu.closeRequested()
            }
            PowerButton {
              Layout.fillWidth: true
              destructive: true
              text: menu.pendingAction ? menu.pendingAction.label : ""
              onClicked: menu.confirm()
            }
          }
        }
      }
    }
  }

  component PowerTile: Rectangle {
    id: tile

    required property var action
    property bool highlighted: false
    property alias hovered: pointer.containsMouse
    signal activated

    Layout.fillWidth: true
    Layout.preferredHeight: 104
    radius: 14
    color: pointer.pressed ? "#2f3446" : tile.hovered || tile.highlighted ? "#242838" : "#141721"
    border.width: tile.highlighted ? 2 : 1
    border.color: tile.highlighted ? tile.action.accent : tile.hovered ? "#3d4459" : "#262a38"
    Behavior on color {
      ColorAnimation {
        duration: 110
      }
    }

    Column {
      anchors.centerIn: parent
      spacing: 10
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: tile.action.icon
        color: tile.hovered || tile.highlighted ? Qt.lighter(tile.action.accent, 1.12) : tile.action.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 30
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: tile.action.label
        color: "#cad3f5"
        font.family: "Adwaita Sans"
        font.pixelSize: 12
        font.weight: Font.DemiBold
      }
    }

    MouseArea {
      id: pointer
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: tile.activated()
    }
  }

  component PowerButton: Button {
    id: button

    property bool destructive: false

    implicitHeight: 34
    font.family: "Adwaita Sans"
    font.pixelSize: 13
    hoverEnabled: true
    background: Rectangle {
      radius: 10
      color: button.destructive ? button.down ? "#4a2530" : button.hovered ? "#3a2028" : "#191d28" : button.down ? "#343a50" : button.hovered ? "#242838" : "#191d28"
      border.width: 1
      border.color: button.destructive ? "#ed8796" : "#2f3344"
    }
    contentItem: Text {
      text: button.text
      font: button.font
      color: button.destructive ? "#ed8796" : "#cad3f5"
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }
  }
}
