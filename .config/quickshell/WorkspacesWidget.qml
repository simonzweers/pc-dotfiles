// WorkspacesWidget.qml
import QtQuick
import Quickshell.Hyprland

Row {
  id: root
  spacing: 4

  // always shown, even when they don't exist yet
  readonly property var persistent: [1, 2, 3, 4, 9, 10]

  // workspaces without an icon show their number
  readonly property var icons: ({
    1: "\u{E795}",  // terminal
    2: "\u{F0379}", // monitor
    3: "\u{F059F}", // browser
    4: "\u{F082E}", // notebook
    8: "\u{F0B79}", // chat
    9: "\u{F1B6}",  // steam
    10: "\u{F1BC}", // spotify
  })

  // persistent workspaces plus any other open ones (special workspaces have negative ids)
  readonly property var ids: {
    const open = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0)
    return [...new Set([...persistent, ...open])].sort((a, b) => a - b)
  }

  Repeater {
    model: root.ids

    Rectangle {
      id: button
      required property int modelData
      readonly property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
      readonly property bool focused: Hyprland.focusedWorkspace?.id === modelData

      width: 24
      height: 20
      radius: 4
      color: focused ? Theme.yellow : "transparent"

      BarText {
        anchors.centerIn: parent
        text: root.icons[button.modelData] ?? button.modelData
        // empty persistent workspaces are greyed out
        color: button.focused ? Theme.bg : button.workspace?.urgent ? Theme.red : button.workspace ? Theme.fg : Theme.gray
      }

      MouseArea {
        anchors.fill: parent
        // dispatch instead of workspace.activate() so empty persistent workspaces can be opened.
        // hyprland's lua config wraps this in hl.dispatch(...), so pass a lua dispatcher
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + button.modelData + " })")
      }
    }
  }
}
