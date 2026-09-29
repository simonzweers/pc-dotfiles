// VolumeWidget.qml
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

BarText {
  id: root
  // the bar window this widget lives in, used to place the popup on the right screen
  required property PanelWindow bar

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)

  // the sink's audio properties are only populated while it is tracked
  PwObjectTracker { objects: [root.sink] }

  color: muted ? Theme.gray : Theme.orange

  text: (muted ? "󰖁" : "󰕾") + " " + volume + "%"

  // click to open the volume menu, right click to mute, scroll to change volume
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) {
        if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
      } else {
        popup.visible = !popup.visible
      }
    }
    onWheel: wheel => {
      if (!root.sink?.audio) return
      const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
    }
  }

  VolumePopup {
    id: popup
    bar: root.bar
  }
}
