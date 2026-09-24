import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "i18n"

// Application launcher overlay (Mod+D). Entries come from Quickshell's desktop
// entry index, so no external menu reader is involved; the matching is done
// here, scoring where the query lands in an entry's name, generic name or id.
//
// The card, the reveal and the closing fade reuse the panel's popup language
// (ControlCenter/PowerMenu). Like the OSD, the surface stays mapped until the
// close animation has finished, and keyboard focus is only taken while the
// launcher is actually open so the tail of that animation cannot swallow keys.
PanelWindow {
  id: launcher

  required property bool opened
  signal closeRequested
  signal launchRequested(var command, string workingDirectory)

  // Scored matches for the current query, best first: [{ entry, score }].
  property var matches: []
  // Index of the highlighted match, and the entry fields used for matching
  // (lowercased once per index build instead of once per keystroke).
  property var index: []
  property int highlighted: 0
  property real reveal: 0

  readonly property int rowHeight: 40
  readonly property int visibleRows: 8

  color: "transparent"
  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  visible: opened || reveal > 0.01
  exclusionMode: ExclusionMode.Ignore
  focusable: true
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Component.onCompleted: buildIndex()

  onOpenedChanged: {
    if (opened) {
      search.text = "";
      refresh();
      reveal = 1;
      input.forceActiveFocus();
      search.forceActiveFocus();
    } else {
      reveal = 0;
    }
  }

  // The entry index is built asynchronously at session start, so a launcher
  // opened before the scan finishes would otherwise stay empty.
  Connections {
    target: DesktopEntries

    function onApplicationsChanged() {
      launcher.buildIndex();
      if (launcher.opened)
        launcher.refresh();
    }
  }

  function buildIndex() {
    const entries = DesktopEntries.applications.values;
    const built = [];

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];

      if (!entry.name || entry.name.length === 0)
        continue;

      built.push({
        entry: entry,
        name: entry.name.toLowerCase(),
        generic: (entry.genericName || "").toLowerCase(),
        id: (entry.id || "").toLowerCase()
      });
    }

    index = built;
  }

  function refresh() {
    const needle = search.text.trim().toLowerCase();
    const results = [];

    for (let i = 0; i < index.length; i++) {
      if (needle.length === 0) {
        results.push({ entry: index[i].entry, score: 0 });
        continue;
      }

      const score = Math.max(fieldScore(index[i].name, needle, 100), fieldScore(index[i].generic, needle, 40), fieldScore(index[i].id, needle, 20));

      if (score > 0)
        results.push({ entry: index[i].entry, score: score });
    }

    results.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
    matches = results;
    highlighted = 0;
  }

  // Higher is better; -1 means "no match". Substring hits rank above
  // subsequence hits, a hit at a word boundary above one inside a word, and
  // earlier hits above later ones.
  function fieldScore(text, needle, weight) {
    if (!text || text.length === 0)
      return -1;

    const at = text.indexOf(needle);

    if (at === 0)
      return weight + 60;
    if (at > 0)
      return weight + (" -_./(".includes(text[at - 1]) ? 35 : 10) - Math.min(at, 25);

    return subsequenceScore(text, needle, weight);
  }

  function subsequenceScore(text, needle, weight) {
    let from = 0;
    let gaps = 0;
    let previous = -1;

    for (let i = 0; i < needle.length; i++) {
      const at = text.indexOf(needle[i], from);

      if (at === -1)
        return -1;
      if (previous >= 0)
        gaps += at - previous - 1;

      previous = at;
      from = at + 1;
    }

    return Math.max(1, weight - Math.min(gaps, 40));
  }

  function move(delta) {
    if (matches.length === 0)
      return;

    highlighted = (highlighted + delta + matches.length) % matches.length;
  }

  function launch() {
    const match = matches[highlighted];

    if (!match)
      return;

    const entry = match.entry;
    // foot takes the command directly (-e is accepted but ignored), matching
    // the terminal the session binds to Mod+Return.
    const command = entry.runInTerminal ? ["foot"].concat(entry.command) : entry.command;

    if (!command || command.length === 0)
      return;

    closeRequested();
    launchRequested(command, entry.workingDirectory);
  }

  Item {
    id: input

    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: launcher.closeRequested()

    // Dim the desktop; clicks on the scrim cancel.
    Rectangle {
      anchors.fill: parent
      color: "#990b0d12"
      MouseArea {
        anchors.fill: parent
        onClicked: launcher.closeRequested()
      }
    }

    Rectangle {
      id: dialog

      anchors.centerIn: parent
      width: 560
      implicitHeight: body.height + 28
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
      opacity: launcher.reveal
      scale: 0.97 + 0.03 * launcher.reveal
      Behavior on opacity {
        NumberAnimation {
          duration: 140
          easing.type: Easing.OutCubic
        }
      }
      Behavior on scale {
        NumberAnimation {
          duration: 160
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
            position: 1.0
            color: "#c6a0f6"
          }
        }
      }

      Column {
        id: body

        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
        }
        anchors.margins: 14
        spacing: 10

        Item {
          id: searchRow

          width: parent.width
          height: 40

          Text {
            id: searchIcon

            anchors {
              left: parent.left
              verticalCenter: parent.verticalCenter
            }
            text: "󰍉"
            color: "#8aadf4"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
          }

          TextInput {
            id: search

            anchors {
              left: searchIcon.right
              leftMargin: 10
              right: parent.right
              verticalCenter: parent.verticalCenter
            }
            color: "#cad3f5"
            selectionColor: "#8aadf4"
            selectedTextColor: "#11131a"
            font.family: "Adwaita Sans"
            font.pixelSize: 16
            clip: true
            onTextChanged: launcher.refresh()
            onAccepted: launcher.launch()
            Keys.onUpPressed: launcher.move(-1)
            Keys.onDownPressed: launcher.move(1)
            Keys.onEscapePressed: launcher.closeRequested()
          }

          Text {
            anchors {
              left: search.left
              verticalCenter: search.verticalCenter
            }
            visible: search.text.length === 0
            text: Tr.tr("Search applications…")
            color: "#6e738d"
            font: search.font
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: "#262a38"
        }

        Text {
          width: parent.width
          visible: launcher.matches.length === 0
          text: Tr.tr("No matching applications")
          color: "#6e738d"
          font.family: "Adwaita Sans"
          font.pixelSize: 14
          horizontalAlignment: Text.AlignHCenter
          topPadding: 16
          bottomPadding: 16
        }

        ListView {
          id: list

          width: parent.width
          height: launcher.rowHeight * Math.min(launcher.visibleRows, launcher.matches.length) - 2
          visible: launcher.matches.length > 0
          clip: true
          interactive: true
          boundsBehavior: Flickable.StopAtBounds
          model: launcher.matches
          currentIndex: launcher.highlighted
          onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

          delegate: Rectangle {
            id: entryRow

            required property var modelData
            required property int index

            width: list.width
            height: launcher.rowHeight
            radius: 10
            // Hover only tints the row; it never moves the selection, because
            // rebuilding the list re-delivers hover to whatever sits under a
            // stationary pointer and would otherwise steal the match the
            // keyboard is about to launch.
            color: index === launcher.highlighted ? "#242838" : pointer.containsMouse ? "#1a1d27" : "transparent"
            Behavior on color {
              ColorAnimation {
                duration: 110
              }
            }

            Rectangle {
              anchors {
                left: parent.left
                leftMargin: 3
                verticalCenter: parent.verticalCenter
              }
              width: 3
              height: 18
              radius: 1.5
              color: "#8aadf4"
              visible: index === launcher.highlighted
            }

            MouseArea {
              id: pointer

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                launcher.highlighted = entryRow.index;
                launcher.launch();
              }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 12
              spacing: 10

              IconImage {
                Layout.alignment: Qt.AlignVCenter
                implicitSize: 20
                source: Quickshell.iconPath(entryRow.modelData.entry.icon.length > 0 ? entryRow.modelData.entry.icon : "application-x-executable")
              }
              Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: entryRow.modelData.entry.name
                color: "#cad3f5"
                font.family: "Adwaita Sans"
                font.pixelSize: 14
                elide: Text.ElideRight
              }
              Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 180
                visible: text.length > 0
                text: entryRow.modelData.entry.genericName || ""
                color: "#6e738d"
                font.family: "Adwaita Sans"
                font.pixelSize: 11
                elide: Text.ElideRight
              }
            }
          }
        }

        Text {
          width: parent.width
          text: Tr.tr("Enter to launch · Esc to close")
          color: "#6e738d"
          font.family: "Adwaita Sans"
          font.pixelSize: 11
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }
}
