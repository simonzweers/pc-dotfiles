// Bar.qml
import Quickshell
import QtQuick

Scope {
	Variants {
		model: Quickshell.screens

		PanelWindow {
			id: panel
			// the dropdown menu currently open on this bar, so opening another closes it
			property var openDropdown: null
			required property var modelData
			screen: modelData

			anchors {
				top: true
				left: true
				right: true
			}

			// float the bar with the same spacing as hyprland's gaps_out
			margins {
				top: 10
				left: 10
				right: 10
			}

			implicitHeight: 30
			color: "transparent"

			Rectangle {
				anchors.fill: parent
				radius: 15
				color: Theme.bg

				ClockWidget {
					anchors.left: parent.left
					anchors.leftMargin: 15
					anchors.verticalCenter: parent.verticalCenter
				}

				WorkspacesWidget {
					anchors.centerIn: parent
				}

				Row {
					anchors.right: parent.right
					anchors.rightMargin: 15
					anchors.verticalCenter: parent.verticalCenter
					spacing: 16

					CpuWidget {}
					MemoryWidget {}
					NetworkWidget { bar: panel }
					BluetoothWidget { bar: panel }
					VolumeWidget { bar: panel }

					// opens the power menu
					BarText {
						text: "\u{F0425}"
						color: Theme.red

						MouseArea {
							anchors.fill: parent
							onClicked: Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.shellDir, "call", "powermenu", "toggle"])
						}
					}
				}
			}
		}
	}
}
