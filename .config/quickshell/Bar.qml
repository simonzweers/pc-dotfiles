// Bar.qml
import Quickshell
import QtQuick

Scope {
	Variants {
		model: Quickshell.screens

		PanelWindow {
			id: panel
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
					BluetoothWidget {}
					VolumeWidget {}
				}
			}
		}
	}
}
