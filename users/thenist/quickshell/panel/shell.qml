//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

ShellRoot {
  id: root

  property date now: new Date()

  function run(command) {
    Quickshell.execDetached(["sh", "-c", command]);
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
            label: "driftwm"
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
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              cursorShape: Qt.PointingHandCursor

              IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: trayItem.modelData.icon
              }

              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
                  trayItem.modelData.display(panel, trayItem.x, trayItem.y + trayItem.height);
                } else {
                  trayItem.modelData.activate();
                }
              }
            }
          }

          ActionPill {
            label: "lock"
            onClicked: root.run("quickshell -n -p ~/.config/quickshell/lock/shell.qml")
          }
        }
      }
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
}
