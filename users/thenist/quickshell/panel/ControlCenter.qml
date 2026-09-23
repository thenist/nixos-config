import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "i18n"

// Control center popup: sound, brightness and network as accent-tinted cards
// under the bar. Session/power actions live behind PowerMenu.qml instead.
PopupWindow {
  id: popup

  required property var desktop
  required property var audio
  required property var outputs

  signal volumeRequested(real value)
  signal muteRequested
  signal commandRequested(string command)

  readonly property var networkColors: ({
      connected: "#a6da95",
      limited: "#eed49f",
      captive: "#eed49f",
      connecting: "#8aadf4",
      offline: "#ed8796",
      unknown: "#6e738d"
    })

  color: "transparent"
  visible: false
  grabFocus: true
  implicitWidth: 360
  implicitHeight: Math.min(640, body.implicitHeight + 32, screen ? screen.height - 80 : 640)
  property real reveal: 0
  onVisibleChanged: {
    if (visible) {
      reveal = 1;
      desktop.refresh();
      content.forceActiveFocus();
    } else {
      reveal = 0;
    }
  }

  function run(command) {
    visible = false;
    commandRequested(command);
  }

  Rectangle {
    id: content

    anchors.fill: parent
    radius: 16
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
    border.color: "#2f3344"
    border.width: 1
    opacity: popup.reveal
    scale: 0.98 + 0.02 * popup.reveal
    transformOrigin: Item.Top
    Behavior on opacity {
      NumberAnimation {
        duration: 130
        easing.type: Easing.OutCubic
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }
    focus: true
    Keys.onEscapePressed: popup.visible = false

    Rectangle {
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
      }
      height: 3
      topLeftRadius: content.radius
      topRightRadius: content.radius
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

    ScrollView {
      anchors.fill: parent
      anchors.margins: 16
      contentWidth: availableWidth
      clip: true

      ColumnLayout {
        id: body

        width: parent.width
        spacing: 12

        RowLayout {
          Layout.fillWidth: true
          Layout.bottomMargin: 2
          spacing: 9
          Text {
            text: "󰒓"
            color: "#8aadf4"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
          }
          Text {
            text: Tr.tr("Controls")
            color: "#cad3f5"
            font.family: "Adwaita Sans"
            font.pixelSize: 17
            font.weight: Font.DemiBold
            Layout.fillWidth: true
          }
          ControlButton {
            Layout.preferredWidth: 30
            text: "󰅖"
            iconFont: true
            foreground: "#6e738d"
            onClicked: popup.visible = false
          }
        }

        Card {
          icon: "󰕾"
          title: Tr.tr("Sound")
          accent: "#8aadf4"
          value: popup.audio ? popup.audio.muted ? Tr.tr("muted") : Math.round(popup.audio.volume * 100) + "%" : "—"

          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ControlButton {
              Layout.preferredWidth: 42
              text: popup.audio && popup.audio.muted ? "󰝟" : "󰕾"
              iconFont: true
              selected: !!(popup.audio && popup.audio.muted)
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
        }

        Card {
          icon: "󰃠"
          title: Tr.tr("Brightness")
          accent: "#eed49f"
          value: popup.desktop.brightness >= 0 ? Math.round(popup.desktop.brightness) + "%" : ""
          visible: popup.desktop.brightness >= 0

          LevelSlider {
            Layout.fillWidth: true
            accent: "#eed49f"
            from: 1
            to: 100
            stepSize: 1
            value: popup.desktop.brightness
            onMoved: popup.desktop.setBrightness(value)
          }
        }

        Card {
          icon: "󰖩"
          title: Tr.tr("Network")
          accent: "#a6da95"

          RowLayout {
            Layout.fillWidth: true
            spacing: 9
            Rectangle {
              Layout.alignment: Qt.AlignTop
              Layout.topMargin: 4
              width: 8
              height: 8
              radius: 4
              color: popup.networkColors[popup.desktop.networkKind] || "#6e738d"
              SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: popup.desktop.networkKind === "connecting"
                NumberAnimation {
                  to: 0.3
                  duration: 700
                  easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                  to: 1.0
                  duration: 700
                  easing.type: Easing.InOutQuad
                }
              }
            }
            Label {
              Layout.fillWidth: true
              text: popup.desktop.network
              wrapMode: Text.Wrap
            }
          }

          ControlButton {
            Layout.fillWidth: true
            text: Tr.tr("Network settings ↗")
            onClicked: popup.run("nm-connection-editor")
          }
        }

        Label {
          Layout.fillWidth: true
          visible: text.length > 0
          text: popup.desktop.error
          color: "#ed8796"
          wrapMode: Text.Wrap
        }
      }
    }
  }

  component Label: Text {
    color: "#cad3f5"
    font.family: "Adwaita Sans"
    font.pixelSize: 13
  }

  // Section card: accent icon + title row over caller-supplied content.
  component Card: Rectangle {
    id: card

    property string icon: ""
    property string title: ""
    property string value: ""
    property color accent: "#8aadf4"
    default property alias contentData: section.data

    Layout.fillWidth: true
    implicitHeight: section.implicitHeight + 28
    radius: 13
    color: "#171a24"
    border.width: 1
    border.color: "#262a38"

    ColumnLayout {
      id: section

      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
          text: card.icon
          color: card.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
        }
        Text {
          text: card.title
          color: "#cad3f5"
          font.family: "Adwaita Sans"
          font.pixelSize: 13
          font.weight: Font.DemiBold
          Layout.fillWidth: true
        }
        Text {
          text: card.value
          visible: text.length > 0
          color: "#8a93a8"
          font.family: "Adwaita Sans"
          font.pixelSize: 12
        }
      }
    }
  }

  component LevelSlider: Slider {
    id: slider

    property color accent: "#8aadf4"

    implicitHeight: 30
    background: Rectangle {
      x: slider.leftPadding
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: slider.availableWidth
      height: 6
      radius: 3
      color: "#262a38"
      Rectangle {
        width: slider.visualPosition * parent.width
        height: parent.height
        radius: 3
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop {
            position: 0.0
            color: Qt.rgba(slider.accent.r, slider.accent.g, slider.accent.b, 0.45)
          }
          GradientStop {
            position: 1.0
            color: slider.enabled ? slider.accent : "#6e738d"
          }
        }
      }
    }
    handle: Rectangle {
      x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      width: 16
      height: 16
      radius: 8
      color: "#11131a"
      border.width: 3
      border.color: slider.enabled ? slider.accent : "#6e738d"
    }
  }

  component ControlButton: Button {
    id: button

    property bool selected: false
    property bool destructive: false
    property bool iconFont: false
    property color foreground: "#cad3f5"

    implicitHeight: 32
    font.family: button.iconFont ? "JetBrainsMono Nerd Font" : "Adwaita Sans"
    font.pixelSize: 13
    hoverEnabled: true
    background: Rectangle {
      radius: 9
      color: button.down ? "#343a50" : button.hovered || button.selected ? "#242838" : "#11131a"
      border.width: button.selected ? 1 : 0
      border.color: "#8aadf4"
    }
    contentItem: Text {
      text: button.text
      font: button.font
      color: !button.enabled ? "#6e738d" : button.destructive ? "#ed8796" : button.selected ? "#8aadf4" : button.foreground
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
