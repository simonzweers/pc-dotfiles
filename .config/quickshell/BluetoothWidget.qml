// BluetoothWidget.qml
import QtQuick
import Quickshell.Bluetooth

BarText {
	id: root
	readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
	readonly property var connected: adapter?.devices.values.filter(d => d.connected) ?? []

	color: adapter?.enabled ? Theme.blue : Theme.gray

	text: {
		if (!adapter?.enabled) return "󰂲"
		if (connected.length === 1) return "󰂱 " + connected[0].name
		if (connected.length > 1) return "󰂱 " + connected.length
		return "󰂯"
	}

	// click to toggle bluetooth on/off
	MouseArea {
		anchors.fill: parent
		onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
	}
}
