// ClockWidget.qml
import QtQuick

BarText {
	color: Theme.yellow
	// directly access the time property from the Time singleton
	text: Time.time
}
