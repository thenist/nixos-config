import QtQuick
import Quickshell

PanelWindow {
  id: osd
  required property bool shown
  required property string label
  required property real level
  color: "transparent"
  implicitWidth: 280
  implicitHeight: 74
  anchors.bottom: true
  margins.bottom: 80
  exclusionMode: ExclusionMode.Ignore
  focusable: false
  mask: Region {}
  // Keep the surface mapped while fading out, otherwise the window would be
  // gone before the fade is ever drawn.
  visible: osd.shown || content.opacity > 0.01

  Item {
    id: content
    anchors.fill: parent
    opacity: osd.shown ? 1 : 0
    Behavior on opacity {
      NumberAnimation {
        duration: osd.shown ? 120 : 200
        easing.type: Easing.OutCubic
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: 14
      color: "#11131af5"
      border.color: "#2f3344"
      Text {
        x: 18
        y: 14
        text: osd.label
        color: "#cad3f5"
        font.family: "Adwaita Sans"
        font.pixelSize: 14
      }
      Rectangle {
        x: 18
        y: 46
        width: parent.width - 36
        height: 6
        radius: 3
        color: "#2f3344"
        Rectangle {
          width: parent.width * Math.max(0, Math.min(1, osd.level))
          height: parent.height
          radius: 3
          color: "#8aadf4"
          Behavior on width {
            NumberAnimation {
              duration: 80
            }
          }
        }
      }
    }
  }
}
