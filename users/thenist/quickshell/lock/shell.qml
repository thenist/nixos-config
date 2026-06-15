import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland

ShellRoot {
  id: root

  property string status: "Session locked"
  property string pendingPassword: ""
  property bool authenticating: false
  signal clearPassword()

  function unlock(password) {
    if (authenticating || password.length === 0) return;

    pendingPassword = password;
    authenticating = true;
    status = "Checking password";
    pam.start();
  }

  PamContext {
    id: pam

    config: "quickshell-lock"
    user: Quickshell.env("USER") || "thenist"

    onPamMessage: {
      if (messageIsError) root.status = message;
      if (responseRequired) respond(root.pendingPassword);
    }

    onCompleted: function(result) {
      root.authenticating = false;

      if (result === PamResult.Success) {
        lock.locked = false;
        Qt.quit();
        return;
      }

      root.pendingPassword = "";
      root.status = result === PamResult.MaxTries ? "Too many attempts" : "Authentication failed";
      root.clearPassword();
    }

    onError: function(error) {
      root.authenticating = false;
      root.pendingPassword = "";
      root.status = PamError.toString(error);
      root.clearPassword();
    }
  }

  WlSessionLock {
    id: lock

    locked: true

    WlSessionLockSurface {
      color: "#0b0d12"

      Rectangle {
        anchors.fill: parent
        color: "#0b0d12"

        Rectangle {
          width: Math.min(parent.width - 48, 430)
          height: 310
          anchors.centerIn: parent
          radius: 24
          color: "#11131a"
          border.width: 1
          border.color: "#2f3344"

          Column {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 18

            Text {
              width: parent.width
              text: Qt.formatDateTime(new Date(), "HH:mm")
              color: "#cad3f5"
              font.pixelSize: 42
              font.weight: Font.DemiBold
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: parent.width
              text: root.status
              color: root.authenticating ? "#a6da95" : "#8aadf4"
              font.pixelSize: 14
              horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
              width: parent.width
              height: 54
              radius: 14
              color: "#181b25"
              border.width: passwordInput.activeFocus ? 1 : 0
              border.color: "#8aadf4"

              Text {
                anchors.centerIn: parent
                text: "Password"
                color: "#6e738d"
                font.pixelSize: 14
                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
              }

              TextInput {
                id: passwordInput

                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: "#cad3f5"
                selectionColor: "#8aadf4"
                selectedTextColor: "#11131a"
                font.pixelSize: 15
                echoMode: TextInput.Password
                enabled: !root.authenticating
                Keys.onReturnPressed: root.unlock(text)
                Keys.onEnterPressed: root.unlock(text)

                Connections {
                  target: root
                  function onClearPassword() {
                    passwordInput.text = "";
                    passwordInput.forceActiveFocus();
                  }
                }

                Component.onCompleted: forceActiveFocus()
              }
            }

            Text {
              width: parent.width
              text: "Press Enter to unlock"
              color: "#6e738d"
              font.pixelSize: 13
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
      }
    }
  }
}
