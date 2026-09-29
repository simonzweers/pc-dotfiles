// PowerMenu.qml
// fullscreen power menu on the focused monitor
// toggle with `qs ipc call powermenu toggle`; arrows / hjkl to move, enter to pick, escape to close
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
	id: root
	property bool open: false

	readonly property var actions: [
		{ name: "Lock", icon: "\u{F033E}", color: Theme.blue, run: () => Quickshell.execDetached(["hyprlock"]) },
		{ name: "Suspend", icon: "\u{F04B2}", color: Theme.purple, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
		{ name: "Log out", icon: "\u{F0343}", color: Theme.yellow, run: () => Hyprland.dispatch("exit") },
		{ name: "Reboot", icon: "\u{F0709}", color: Theme.orange, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
		{ name: "Power off", icon: "\u{F0425}", color: Theme.red, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
	]

	function trigger(index) {
		open = false
		actions[index].run()
	}

	IpcHandler {
		target: "powermenu"
		function toggle(): void { root.open = !root.open }
		function open(): void { root.open = true }
		function close(): void { root.open = false }
	}

	PanelWindow {
		id: window
		visible: root.open
		screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
		color: "transparent"

		anchors {
			top: true
			bottom: true
			left: true
			right: true
		}

		// cover the bar too, and grab the keyboard while open
		WlrLayershell.layer: WlrLayer.Overlay
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
		WlrLayershell.namespace: "quickshell-powermenu"
		exclusionMode: ExclusionMode.Ignore

		property int selected: 0
		onVisibleChanged: if (visible) selected = 0

		// dimmed backdrop, click it to close
		Rectangle {
			anchors.fill: parent
			color: Qt.rgba(0, 0, 0, 0.5)

			MouseArea {
				anchors.fill: parent
				onClicked: root.open = false
			}
		}

		Rectangle {
			anchors.centerIn: parent
			implicitWidth: buttons.implicitWidth + 40
			implicitHeight: buttons.implicitHeight + 40
			radius: 15
			color: Theme.bg
			border.color: Theme.bg2
			border.width: 2

			focus: true
			Keys.onPressed: event => {
				const count = root.actions.length
				switch (event.key) {
				case Qt.Key_Escape:
					root.open = false
					break
				case Qt.Key_Left:
				case Qt.Key_H:
				case Qt.Key_Up:
				case Qt.Key_K:
				case Qt.Key_Backtab:
					window.selected = (window.selected + count - 1) % count
					break
				case Qt.Key_Right:
				case Qt.Key_L:
				case Qt.Key_Down:
				case Qt.Key_J:
				case Qt.Key_Tab:
					window.selected = (window.selected + 1) % count
					break
				case Qt.Key_Return:
				case Qt.Key_Enter:
				case Qt.Key_Space:
					root.trigger(window.selected)
					break
				default:
					return
				}
				event.accepted = true
			}

			// swallow clicks so they don't reach the backdrop
			MouseArea { anchors.fill: parent }

			Row {
				id: buttons
				anchors.centerIn: parent
				spacing: 15

				Repeater {
					model: root.actions

					Rectangle {
						id: button
						required property var modelData
						required property int index
						readonly property bool active: window.selected === index

						width: 110
						height: 110
						radius: 12
						color: active ? Theme.bg2 : Theme.bg1
						border.color: active ? modelData.color : "transparent"
						border.width: 2

						Column {
							anchors.centerIn: parent
							spacing: 10

							BarText {
								anchors.horizontalCenter: parent.horizontalCenter
								text: button.modelData.icon
								font.pixelSize: 36
								color: button.modelData.color
							}

							BarText {
								anchors.horizontalCenter: parent.horizontalCenter
								text: button.modelData.name
								color: button.active ? Theme.fg : Theme.gray
							}
						}

						MouseArea {
							anchors.fill: parent
							hoverEnabled: true
							onEntered: window.selected = button.index
							onClicked: root.trigger(button.index)
						}
					}
				}
			}
		}
	}
}
