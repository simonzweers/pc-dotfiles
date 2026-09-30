// ScreenshotWidget.qml
import QtQuick
import Quickshell

BarText {
	id: root
	// the bar window this widget lives in, used to place the popup on the right screen
	required property PanelWindow bar

	text: "\u{F0100}"
	color: Theme.aqua

	// click to open the screenshot menu
	MouseArea {
		anchors.fill: parent
		onClicked: popup.visible = !popup.visible
	}

	ScreenshotPopup {
		id: popup
		bar: root.bar
	}
}
