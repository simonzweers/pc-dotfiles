// CpuWidget.qml
import QtQuick

BarText {
	color: Theme.aqua
	text: "󰻠 " + Math.round(SystemStats.cpuUsage) + "%"
}
