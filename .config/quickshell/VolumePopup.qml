// VolumePopup.qml
// dropdown for output/input devices and their volume, plus per-application volume
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

DropdownWindow {
	id: popup
	implicitWidth: 380

	readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
	readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
	// applications playing audio
	readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isSink && n.isStream)

	// volume and app names are only available for tracked nodes
	PwObjectTracker {
		objects: popup.visible ? [...popup.sinks, ...popup.sources, ...popup.streams] : []
	}

	// a selectable output or input device
	component DeviceRow: Rectangle {
		id: device
		required property PwNode modelData
		property bool selected: false
		signal picked()

		Layout.fillWidth: true
		implicitHeight: 28
		radius: 8
		color: mouse.containsMouse ? Theme.bg1 : "transparent"

		RowLayout {
			anchors.fill: parent
			anchors.leftMargin: 8
			anchors.rightMargin: 8
			spacing: 8

			BarText {
				text: device.selected ? "\u{F0134}" : "\u{F0130}"
				color: device.selected ? Theme.yellow : Theme.gray
			}

			BarText {
				Layout.fillWidth: true
				text: device.modelData.description || device.modelData.name
				elide: Text.ElideRight
				color: device.selected ? Theme.yellow : Theme.fg
			}
		}

		MouseArea {
			id: mouse
			anchors.fill: parent
			hoverEnabled: true
			onClicked: device.picked()
		}
	}

	BarText {
		text: "Output"
		font.bold: true
	}

	VolumeSlider {
		Layout.fillWidth: true
		node: Pipewire.defaultAudioSink
	}

	// device picker, only when there's a choice
	Repeater {
		model: popup.sinks.length > 1 ? popup.sinks : []

		DeviceRow {
			selected: modelData === Pipewire.defaultAudioSink
			onPicked: Pipewire.preferredDefaultAudioSink = modelData
		}
	}

	BarText {
		Layout.topMargin: 6
		text: "Input"
		font.bold: true
	}

	VolumeSlider {
		Layout.fillWidth: true
		node: Pipewire.defaultAudioSource
		icon: "\u{F036C}"
		mutedIcon: "\u{F036D}"
	}

	Repeater {
		model: popup.sources.length > 1 ? popup.sources : []

		DeviceRow {
			selected: modelData === Pipewire.defaultAudioSource
			onPicked: Pipewire.preferredDefaultAudioSource = modelData
		}
	}

	BarText {
		Layout.topMargin: 6
		visible: popup.streams.length > 0
		text: "Applications"
		font.bold: true
	}

	Repeater {
		model: popup.streams

		ColumnLayout {
			id: stream
			required property PwNode modelData

			Layout.fillWidth: true
			spacing: 2

			BarText {
				Layout.fillWidth: true
				text: stream.modelData.properties["application.name"] || stream.modelData.description || stream.modelData.name
				color: Theme.gray
				elide: Text.ElideRight
			}

			VolumeSlider {
				Layout.fillWidth: true
				node: stream.modelData
			}
		}
	}
}
