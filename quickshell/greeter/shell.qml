import QtQuick
import Quickshell
import Quickshell.Services.Greetd

ShellRoot {
  id: root

  property string status: Greetd.available ? "Sign in to driftwm" : "greetd socket unavailable"
  property bool busy: false

  function submit() {
    if (busy || !Greetd.available) return;
    if (userField.text.length === 0) {
      status = "Enter a user name";
      return;
    }
    if (passwordField.text.length === 0) {
      status = "Enter a password";
      return;
    }

    busy = true;
    status = "Authenticating";
    Greetd.createSession(userField.text);
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (error) root.status = message;
      if (responseRequired) Greetd.respond(passwordField.text);
    }

    function onReadyToLaunch() {
      root.status = "Starting driftwm";
      Greetd.launch(["/run/current-system/sw/bin/driftwm-session"]);
    }

    function onAuthFailure(message) {
      root.busy = false;
      root.status = message || "Authentication failed";
      passwordField.text = "";
      passwordField.forceActiveFocus();
    }

    function onError(error) {
      root.busy = false;
      root.status = error;
    }
  }

  FloatingWindow {
    id: window

    title: "driftwm greeter"
    color: "#0b0d12"
    fullscreen: true
    implicitWidth: screen ? screen.width : 1280
    implicitHeight: screen ? screen.height : 720

    Rectangle {
      anchors.fill: parent
      color: "#0b0d12"

      Rectangle {
        width: Math.min(parent.width - 48, 460)
        height: 390
        anchors.centerIn: parent
        radius: 24
        color: "#11131a"
        border.width: 1
        border.color: "#2f3344"

        Column {
          anchors.fill: parent
          anchors.margins: 34
          spacing: 18

          Text {
            width: parent.width
            text: "driftwm"
            color: "#cad3f5"
            font.pixelSize: 34
            font.weight: Font.DemiBold
          }

          Text {
            width: parent.width
            text: root.status
            color: root.busy ? "#a6da95" : "#8aadf4"
            font.pixelSize: 14
            wrapMode: Text.Wrap
          }

          Field {
            id: userField
            label: "User"
            text: "thenist"
            enabled: !root.busy
            onAccepted: passwordField.forceActiveFocus()
          }

          Field {
            id: passwordField
            label: "Password"
            password: true
            enabled: !root.busy
            onAccepted: root.submit()
          }

          Rectangle {
            width: parent.width
            height: 48
            radius: 14
            color: root.busy ? "#363a4f" : "#8aadf4"

            Text {
              anchors.centerIn: parent
              text: root.busy ? "Signing in" : "Sign in"
              color: root.busy ? "#a5adcb" : "#11131a"
              font.pixelSize: 15
              font.weight: Font.DemiBold
            }

            MouseArea {
              anchors.fill: parent
              enabled: !root.busy
              cursorShape: Qt.PointingHandCursor
              onClicked: root.submit()
            }
          }
        }
      }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
  }

  component Field: Rectangle {
    id: field

    property alias text: input.text
    property string label: ""
    property bool password: false
    signal accepted()

    width: parent.width
    height: 54
    radius: 14
    color: "#181b25"
    border.width: input.activeFocus ? 1 : 0
    border.color: "#8aadf4"

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      text: field.label
      color: "#6e738d"
      font.pixelSize: 14
      visible: input.text.length === 0 && !input.activeFocus
    }

    TextInput {
      id: input

      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      color: "#cad3f5"
      selectionColor: "#8aadf4"
      selectedTextColor: "#11131a"
      font.pixelSize: 15
      echoMode: field.password ? TextInput.Password : TextInput.Normal
      Keys.onReturnPressed: field.accepted()
      Keys.onEnterPressed: field.accepted()
    }
  }
}
