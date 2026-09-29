// PillButton.qml
// rounded button used in the dropdown menus
import QtQuick

Rectangle {
	id: button
	property alias text: label.text
	property bool highlighted: false
	signal clicked()

	implicitWidth: label.implicitWidth + 20
	implicitHeight: 24
	radius: 12
	color: highlighted ? Theme.yellow : mouse.containsMouse ? Theme.bg2 : Theme.bg1

	BarText {
		id: label
		anchors.centerIn: parent
		color: button.highlighted ? Theme.bg : Theme.fg
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		onClicked: button.clicked()
	}
}
