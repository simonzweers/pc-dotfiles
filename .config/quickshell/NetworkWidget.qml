// NetworkWidget.qml
import QtQuick
import Quickshell

BarText {
	id: root
	// the bar window this widget lives in, used to place the popup on the right screen
	required property PanelWindow bar

	readonly property string wifiIcon: Network.signal > 75 ? "\u{F0928}" : Network.signal > 50 ? "\u{F0925}" : Network.signal > 25 ? "\u{F0922}" : "\u{F091F}"

	color: Network.type ? Theme.green : Theme.gray
	text: {
		if (Network.type === "ethernet") return "\u{F0200}"
		if (Network.type === "wifi") return wifiIcon + " " + Network.connection
		return "\u{F092E}"
	}

	// click to open the network menu
	MouseArea {
		anchors.fill: parent
		onClicked: popup.visible = !popup.visible
	}

	NetworkPopup {
		id: popup
		bar: root.bar
	}
}
