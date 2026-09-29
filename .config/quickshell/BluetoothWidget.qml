// BluetoothWidget.qml
import QtQuick
import Quickshell
import Quickshell.Bluetooth

BarText {
	id: root
	// the bar window this widget lives in, used to place the popup on the right screen
	required property PanelWindow bar

	readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
	readonly property var connected: adapter?.devices.values.filter(d => d.connected) ?? []

	color: adapter?.enabled ? Theme.blue : Theme.gray

	text: {
		if (!adapter?.enabled) return "󰂲"
		if (connected.length === 1) return "󰂱 " + connected[0].name
		if (connected.length > 1) return "󰂱 " + connected.length
		return "󰂯"
	}

	// click to open the bluetooth menu, right click to toggle bluetooth on/off
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		onClicked: mouse => {
			if (mouse.button === Qt.RightButton) {
				if (root.adapter) root.adapter.enabled = !root.adapter.enabled
			} else {
				popup.visible = !popup.visible
			}
		}
	}

	BluetoothPopup {
		id: popup
		bar: root.bar
	}
}
