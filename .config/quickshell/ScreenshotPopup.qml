// ScreenshotPopup.qml
// dropdown to take a screenshot of the focused monitor, the active window or a region
import QtQuick
import QtQuick.Layouts
import Quickshell

DropdownWindow {
	id: popup
	implicitWidth: 260

	readonly property var modes: [
		{ name: "Screen", mode: "screen", icon: "\u{F0379}", keys: "Super+Shift+Ctrl+F12" },
		{ name: "Window", mode: "window", icon: "\u{F05B6}", keys: "Super+Shift+F12" },
		{ name: "Region", mode: "region", icon: "\u{F0A70}", keys: "Super+F12" },
	]

	BarText {
		text: "Screenshot"
		font.bold: true
	}

	Repeater {
		model: popup.modes

		Rectangle {
			id: row
			required property var modelData

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
					text: row.modelData.icon
					color: Theme.aqua
				}

				BarText {
					Layout.fillWidth: true
					text: row.modelData.name
				}

				BarText {
					text: row.modelData.keys
					color: Theme.gray
					font.pixelSize: 11
				}
			}

			MouseArea {
				id: mouse
				anchors.fill: parent
				hoverEnabled: true
				// close first so the menu isn't in the screenshot
				onClicked: {
					popup.visible = false
					Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.shellDir, "call", "screenshot", row.modelData.mode + "Delayed"])
				}
			}
		}
	}
}
