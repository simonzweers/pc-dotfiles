// NetworkPopup.qml
// dropdown for managing wifi, with a link to nmtui for everything else
import QtQuick
import QtQuick.Layouts
import Quickshell

DropdownWindow {
	id: popup

	// the ssid whose password field is open
	property string passwordFor: ""

	onVisibleChanged: {
		passwordFor = ""
		if (visible) {
			Network.error = ""
			Network.scan()
		}
	}

	RowLayout {
		Layout.fillWidth: true

		BarText {
			text: "Wi-Fi"
			font.bold: true
			Layout.fillWidth: true
		}

		PillButton {
			text: Network.wifiEnabled ? "On" : "Off"
			highlighted: Network.wifiEnabled
			onClicked: Network.setWifiEnabled(!Network.wifiEnabled)
		}
	}

	BarText {
		Layout.fillWidth: true
		color: Theme.gray
		elide: Text.ElideRight
		text: Network.busy ? "Working…"
			: Network.type ? "Connected via " + Network.type + ": " + Network.connection
			: "Not connected"
	}

	BarText {
		Layout.fillWidth: true
		visible: Network.error !== ""
		color: Theme.red
		wrapMode: Text.Wrap
		text: Network.error
	}

	ListView {
		Layout.fillWidth: true
		Layout.preferredHeight: 300
		clip: true
		spacing: 2
		visible: Network.wifiEnabled
		model: Network.networks

		delegate: Column {
			id: entry
			required property var modelData
			readonly property bool showPassword: popup.passwordFor === modelData.ssid

			width: ListView.view.width

			Rectangle {
				width: parent.width
				height: 30
				radius: 8
				color: row.containsMouse ? Theme.bg1 : "transparent"

				RowLayout {
					anchors.fill: parent
					anchors.leftMargin: 8
					anchors.rightMargin: 8
					spacing: 8

					BarText {
						text: entry.modelData.signal > 75 ? "\u{F0928}" : entry.modelData.signal > 50 ? "\u{F0925}" : entry.modelData.signal > 25 ? "\u{F0922}" : "\u{F091F}"
						color: entry.modelData.active ? Theme.yellow : Theme.fg
					}

					BarText {
						Layout.fillWidth: true
						text: entry.modelData.ssid
						elide: Text.ElideRight
						color: entry.modelData.active ? Theme.yellow : Theme.fg
					}

					BarText {
						text: entry.modelData.active ? "Disconnect" : entry.modelData.saved ? "Saved" : ""
						color: Theme.gray
					}

					BarText {
						text: entry.modelData.secure ? "\u{F033E}" : ""
						color: Theme.gray
					}
				}

				// click to connect, or disconnect from the active network
				MouseArea {
					id: row
					anchors.fill: parent
					hoverEnabled: true
					onClicked: {
						const network = entry.modelData
						if (network.active)
							Network.disconnect(network.ssid)
						else if (network.secure && !network.saved)
							popup.passwordFor = entry.showPassword ? "" : network.ssid
						else
							Network.connect(network.ssid)
					}
				}
			}

			// password field for secured networks that haven't been saved yet
			Rectangle {
				visible: entry.showPassword
				width: parent.width
				height: visible ? 32 : 0
				radius: 8
				color: Theme.bg1
				border.color: Theme.yellow
				border.width: 1

				TextInput {
					id: password
					anchors.fill: parent
					anchors.leftMargin: 10
					anchors.rightMargin: 10
					verticalAlignment: TextInput.AlignVCenter
					echoMode: TextInput.Password
					color: Theme.fg
					font.family: "CaskaydiaCove Nerd Font"
					font.pixelSize: 13
					focus: entry.showPassword
					onVisibleChanged: if (visible) forceActiveFocus(); else text = ""
					onAccepted: {
						Network.connect(entry.modelData.ssid, text)
						popup.passwordFor = ""
					}
					Keys.onEscapePressed: popup.passwordFor = ""

					BarText {
						anchors.verticalCenter: parent.verticalCenter
						visible: password.text === ""
						text: "Password, then Enter"
						color: Theme.gray
					}
				}
			}
		}
	}

	BarText {
		Layout.fillWidth: true
		Layout.preferredHeight: 300
		visible: !Network.wifiEnabled
		color: Theme.gray
		text: "Wi-Fi is off"
	}

	RowLayout {
		Layout.fillWidth: true

		PillButton {
			text: "\u{F0450} Rescan"
			onClicked: Network.scan()
		}

		Item { Layout.fillWidth: true }

		PillButton {
			text: "\u{F0493} Advanced settings"
			onClicked: {
				popup.visible = false
				Network.openSettings()
			}
		}
	}
}
