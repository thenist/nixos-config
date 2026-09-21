import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

PopupWindow {
  id: popup
  required property var desktop
  required property var audio
  required property var outputs
  required property string outputName
  signal volumeRequested(real value)
  signal muteRequested
  signal commandRequested(string command)
  property string pendingPower: ""

  color: "transparent"
  visible: false
  grabFocus: true
  implicitWidth: 340
  implicitHeight: Math.min(620, body.implicitHeight + 32, screen ? screen.height - 80 : 620)
  onVisibleChanged: {
    pendingPower = "";
    if (visible) {
      desktop.refresh();
      content.forceActiveFocus();
    }
  }

  function run(command) {
    visible = false;
    commandRequested(command);
  }

  Rectangle {
    id: content
    anchors.fill: parent
    color: "#11131af5"
    radius: 14
    border.color: "#2f3344"
    border.width: 1
    focus: true
    Keys.onEscapePressed: popup.visible = false

    ScrollView {
      anchors.fill: parent
      anchors.margins: 16
      contentWidth: availableWidth
      clip: true
      ColumnLayout {
        id: body
        width: parent.width
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          Label {
            text: "Controls"
            font.pixelSize: 17
            font.bold: true
            Layout.fillWidth: true
          }
          ControlButton {
            text: "Close"
            onClicked: popup.visible = false
          }
        }

        Label {
          text: "Sound"
          color: "#8aadf4"
        }
        Label {
          text: popup.outputName
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
        RowLayout {
          Layout.fillWidth: true
          ControlButton {
            text: popup.audio && popup.audio.muted ? "Unmute" : "Mute"
            enabled: !!popup.audio
            onClicked: popup.muteRequested()
          }
          LevelSlider {
            Layout.fillWidth: true
            from: 0
            to: 1
            stepSize: 0.01
            enabled: !!popup.audio
            value: popup.audio ? popup.audio.volume : 0
            onMoved: popup.volumeRequested(value)
          }
          Label {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: popup.audio ? Math.round(popup.audio.volume * 100) + "%" : "—"
          }
        }
        Repeater {
          model: popup.outputs
          ControlButton {
            required property var modelData
            Layout.fillWidth: true
            text: (Pipewire.defaultAudioSink === modelData ? "✓  " : "") + (modelData.description || modelData.nickname || modelData.name)
            selected: Pipewire.defaultAudioSink === modelData
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
          }
        }

        Label {
          visible: popup.desktop.brightness >= 0
          text: "Brightness"
          color: "#8aadf4"
        }
        RowLayout {
          visible: popup.desktop.brightness >= 0
          Layout.fillWidth: true
          LevelSlider {
            Layout.fillWidth: true
            from: 1
            to: 100
            stepSize: 1
            value: popup.desktop.brightness
            onMoved: popup.desktop.setBrightness(value)
          }
          Label {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(popup.desktop.brightness) + "%"
          }
        }
        Label {
          visible: text.length > 0
          text: popup.desktop.error
          color: "#ed8796"
        }

        Label {
          text: "Network"
          color: "#8aadf4"
        }
        Label {
          text: popup.desktop.network
          Layout.fillWidth: true
          wrapMode: Text.Wrap
        }
        ControlButton {
          text: "Network settings ↗"
          Layout.fillWidth: true
          onClicked: popup.run("nm-connection-editor")
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 1
          color: "#2f3344"
        }
        RowLayout {
          Layout.fillWidth: true
          ControlButton {
            text: "Lock"
            Layout.fillWidth: true
            onClicked: popup.run("quickshell -n -p ~/.config/quickshell/lock/shell.qml")
          }
          ControlButton {
            text: "Suspend"
            Layout.fillWidth: true
            onClicked: popup.run("systemctl suspend")
          }
        }
        RowLayout {
          Layout.fillWidth: true
          ControlButton {
            text: "Restart"
            Layout.fillWidth: true
            onClicked: popup.pendingPower = "reboot"
          }
          ControlButton {
            text: "Shut down"
            Layout.fillWidth: true
            onClicked: popup.pendingPower = "poweroff"
          }
        }
        RowLayout {
          visible: popup.pendingPower.length > 0
          Layout.fillWidth: true
          ControlButton {
            text: popup.pendingPower === "reboot" ? "Confirm restart" : "Confirm shutdown"
            Layout.fillWidth: true
            destructive: true
            onClicked: popup.run("systemctl " + popup.pendingPower)
          }
          ControlButton {
            text: "Cancel"
            onClicked: popup.pendingPower = ""
          }
        }
      }
    }
  }

  component Label: Text {
    color: "#cad3f5"
    font.family: "Adwaita Sans"
    font.pixelSize: 13
  }

  component LevelSlider: Slider {
    id: slider
    implicitHeight: 32
    background: Rectangle {
      x: slider.leftPadding
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: slider.availableWidth
      height: 5
      radius: 3
      color: "#2f3344"
      Rectangle {
        width: slider.visualPosition * parent.width
        height: parent.height
        radius: 3
        color: slider.enabled ? "#8aadf4" : "#6e738d"
      }
    }
    handle: Rectangle {
      x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: 14
      height: 14
      radius: 7
      color: slider.pressed ? "#cad3f5" : "#8aadf4"
      border.width: slider.activeFocus ? 2 : 0
      border.color: "#cad3f5"
    }
  }

  component ControlButton: Button {
    id: button
    property bool selected: false
    property bool destructive: false
    implicitHeight: 32
    font.family: "Adwaita Sans"
    font.pixelSize: 13
    hoverEnabled: true
    background: Rectangle {
      radius: 8
      color: button.down ? "#343a50" : button.hovered || button.selected ? "#242838" : "#181b25"
      border.width: button.activeFocus ? 1 : 0
      border.color: "#8aadf4"
    }
    contentItem: Text {
      text: button.text
      font: button.font
      color: !button.enabled ? "#6e738d" : button.destructive ? "#ed8796" : button.selected ? "#8aadf4" : "#cad3f5"
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
