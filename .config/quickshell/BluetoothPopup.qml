// BluetoothPopup.qml
// dropdown for turning bluetooth on/off and pairing, connecting and forgetting devices
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

DropdownWindow {
	id: popup

	readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

	// named or paired devices (unnamed ones are usually unconnectable noise); connected first, then paired
	readonly property var devices: (adapter?.devices.values ?? [])
		.filter(d => d.paired || d.deviceName !== "")
		.sort((a, b) => b.connected - a.connected || b.paired - a.paired || a.name.localeCompare(b.name))

	// addresses of devices to connect to as soon as pairing from this menu finishes
	property var pendingConnect: []

	// scan for new devices while the menu is open
	onVisibleChanged: if (adapter?.enabled) adapter.discovering = visible

	function deviceIcon(device) {
		if (device.icon.startsWith("audio-head")) return "\u{F02CB}"
		if (device.icon.startsWith("audio")) return "\u{F04C3}"
		if (device.icon === "phone") return "\u{F03F2}"
		if (device.icon === "input-mouse") return "\u{F037D}"
		if (device.icon === "input-keyboard") return "\u{F030C}"
		if (device.icon === "input-gaming") return "\u{F0297}"
		return "\u{F00AF}"
	}

	function deviceStatus(device) {
		if (device.pairing) return "Pairing…"
		if (device.state === BluetoothDeviceState.Connecting) return "Connecting…"
		if (device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
		if (device.connected) return device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "Connected"
		if (device.paired) return "Paired"
		return ""
	}

	Instantiator {
		model: popup.adapter?.devices ?? []

		Connections {
			required property BluetoothDevice modelData
			target: modelData

			function onPairedChanged() {
				if (!modelData.paired || !popup.pendingConnect.includes(modelData.address)) return
				popup.pendingConnect = popup.pendingConnect.filter(a => a !== modelData.address)
				// trusted devices reconnect automatically in the future
				modelData.trusted = true
				modelData.connect()
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true

		BarText {
			text: "Bluetooth"
			font.bold: true
			Layout.fillWidth: true
		}

		PillButton {
			visible: popup.adapter !== null
			text: popup.adapter?.enabled ? "On" : "Off"
			highlighted: popup.adapter?.enabled ?? false
			onClicked: {
				popup.adapter.enabled = !popup.adapter.enabled
				if (popup.adapter.enabled) popup.adapter.discovering = true
			}
		}
	}

	BarText {
		Layout.fillWidth: true
		color: Theme.gray
		text: !popup.adapter ? "No Bluetooth adapter found"
			: !popup.adapter.enabled ? "Bluetooth is off"
			: popup.adapter.discovering ? "Scanning for devices…"
			: popup.devices.length + " devices"
	}

	ListView {
		Layout.fillWidth: true
		Layout.preferredHeight: Math.min(contentHeight, 300)
		clip: true
		spacing: 2
		visible: popup.adapter?.enabled ?? false
		model: popup.devices

		delegate: Rectangle {
			id: entry
			required property BluetoothDevice modelData

			width: ListView.view.width
			height: 30
			radius: 8
			color: row.containsMouse ? Theme.bg1 : "transparent"

			// click to connect, disconnect, or pair a new device
			MouseArea {
				id: row
				anchors.fill: parent
				hoverEnabled: true
				onClicked: {
					const device = entry.modelData
					if (device.pairing) return
					if (device.connected) {
						device.disconnect()
					} else if (device.paired) {
						device.connect()
					} else {
						popup.pendingConnect = [...popup.pendingConnect, device.address]
						device.pair()
					}
				}
			}

			RowLayout {
				anchors.fill: parent
				anchors.leftMargin: 8
				anchors.rightMargin: 8
				spacing: 8

				BarText {
					text: popup.deviceIcon(entry.modelData)
					color: entry.modelData.connected ? Theme.blue : Theme.fg
				}

				BarText {
					Layout.fillWidth: true
					text: entry.modelData.name
					elide: Text.ElideRight
					color: entry.modelData.connected ? Theme.blue : Theme.fg
				}

				BarText {
					text: popup.deviceStatus(entry.modelData)
					color: Theme.gray
				}

				// remove a paired device
				BarText {
					visible: entry.modelData.paired
					text: "\u{F0156}"
					color: forget.containsMouse ? Theme.red : Theme.gray

					MouseArea {
						id: forget
						anchors.fill: parent
						hoverEnabled: true
						onClicked: entry.modelData.forget()
					}
				}
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true

		PillButton {
			visible: popup.adapter?.enabled ?? false
			text: popup.adapter?.discovering ? "\u{F04DB} Stop scan" : "\u{F0450} Scan"
			onClicked: popup.adapter.discovering = !popup.adapter.discovering
		}

		Item { Layout.fillWidth: true }

		// bluetoothctl for devices that need a PIN, and anything else not covered here
		PillButton {
			text: "\u{F0493} Advanced settings"
			onClicked: {
				popup.visible = false
				Quickshell.execDetached(["ghostty", "-e", "bluetoothctl"])
			}
		}
	}
}
