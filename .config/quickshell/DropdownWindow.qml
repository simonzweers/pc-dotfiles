// DropdownWindow.qml
// base for the dropdown menus that open below the bar; children are laid out in a column
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
	id: dropdown
	required property PanelWindow bar
	default property alias content: layout.data

	screen: bar.screen
	visible: false
	color: "transparent"

	anchors {
		top: true
		right: true
	}

	// sits below the bar, with the same gap as hyprland's gaps_out
	margins {
		top: 10
		right: 10
	}

	// don't push windows out of the way
	exclusionMode: ExclusionMode.Normal
	exclusiveZone: 0

	// allow typing into text fields
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

	implicitWidth: 340
	implicitHeight: layout.implicitHeight + 30

	// only one dropdown is open at a time
	onVisibleChanged: {
		if (!visible) return
		if (bar.openDropdown && bar.openDropdown !== dropdown)
			bar.openDropdown.visible = false
		bar.openDropdown = dropdown
	}

	// close when clicking anywhere outside the dropdown or the bar
	HyprlandFocusGrab {
		windows: [dropdown, dropdown.bar]
		active: dropdown.visible
		onCleared: dropdown.visible = false
	}

	Rectangle {
		anchors.fill: parent
		radius: 15
		color: Theme.bg
		border.color: Theme.bg2
		border.width: 2

		// escape closes the dropdown
		focus: true
		Keys.onEscapePressed: dropdown.visible = false

		ColumnLayout {
			id: layout
			anchors.fill: parent
			anchors.margins: 15
			spacing: 10
		}
	}
}
