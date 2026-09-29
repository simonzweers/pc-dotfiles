// MemoryWidget.qml
import QtQuick

BarText {
	color: Theme.purple
	text: "󰍛 " + SystemStats.memUsedGb.toFixed(1) + "G (" + Math.round(SystemStats.memUsage) + "%)"
}
