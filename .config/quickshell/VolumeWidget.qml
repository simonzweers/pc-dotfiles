// VolumeWidget.qml
import QtQuick
import Quickshell.Services.Pipewire

BarText {
  id: root
  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)

  // the sink's audio properties are only populated while it is tracked
  PwObjectTracker { objects: [root.sink] }

  color: muted ? Theme.gray : Theme.orange

  text: (muted ? "󰖁" : "󰕾") + " " + volume + "%"

  // click to mute, scroll to change volume
  MouseArea {
    anchors.fill: parent
    onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
    onWheel: wheel => {
      if (!root.sink?.audio) return
      const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
    }
  }
}
