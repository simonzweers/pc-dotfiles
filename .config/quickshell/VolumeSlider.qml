// VolumeSlider.qml
// mute button, draggable volume bar and percentage for one pipewire node
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

RowLayout {
	id: root
	required property PwNode node
	property string icon: "\u{F057E}"
	property string mutedIcon: "\u{F0581}"

	readonly property bool muted: node?.audio?.muted ?? false
	readonly property real volume: node?.audio?.volume ?? 0

	function setVolume(value) {
		if (node?.audio) node.audio.volume = Math.max(0, Math.min(1, value))
	}

	spacing: 10

	// click the icon to mute
	BarText {
		Layout.preferredWidth: 16
		text: root.muted ? root.mutedIcon : root.icon
		color: root.muted ? Theme.gray : Theme.orange

		MouseArea {
			anchors.fill: parent
			onClicked: if (root.node?.audio) root.node.audio.muted = !root.muted
		}
	}

	// click or drag to set the volume, scroll to adjust it
	Item {
		Layout.fillWidth: true
		implicitHeight: 16

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width
			height: 6
			radius: 3
			color: Theme.bg2

			Rectangle {
				width: parent.width * Math.min(root.volume, 1)
				height: parent.height
				radius: 3
				color: root.muted ? Theme.gray : Theme.orange
			}
		}

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			x: parent.width * Math.min(root.volume, 1) - width / 2
			width: 14
			height: 14
			radius: 7
			color: Theme.fg
		}

		MouseArea {
			anchors.fill: parent
			onPressed: mouse => root.setVolume(mouse.x / width)
			onPositionChanged: mouse => root.setVolume(mouse.x / width)
			onWheel: wheel => root.setVolume(root.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
		}
	}

	BarText {
		Layout.preferredWidth: 36
		horizontalAlignment: Text.AlignRight
		text: Math.round(root.volume * 100) + "%"
		color: root.muted ? Theme.gray : Theme.fg
	}
}
