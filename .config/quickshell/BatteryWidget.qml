// BatteryWidget.qml
import QtQuick
import Quickshell.Services.UPower

BarText {
	id: root

	readonly property UPowerDevice device: UPower.displayDevice
	readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
	readonly property bool charging: device?.state === UPowerDeviceState.Charging
		|| device?.state === UPowerDeviceState.PendingCharge
		|| device?.state === UPowerDeviceState.FullyCharged
	// click to swap the percentage for the time until empty/full
	property bool showTime: false

	// formats seconds as e.g. "1h 05m" or "18m"
	function formatTime(seconds) {
		const h = Math.floor(seconds / 3600)
		const m = Math.floor(seconds % 3600 / 60)
		return h > 0 ? h + "h " + String(m).padStart(2, "0") + "m" : m + "m"
	}

	// hidden on machines without a battery
	visible: device?.ready && device.isLaptopBattery

	color: {
		if (charging) return Theme.green
		if (percent <= 15) return Theme.red
		if (percent <= 30) return Theme.yellow
		return Theme.fg
	}

	text: {
		// nerd font battery icons for 0, 10, ..., 100%
		const icons = charging
			? ["\u{F089F}", "\u{F089C}", "\u{F0086}", "\u{F0087}", "\u{F0088}", "\u{F089D}", "\u{F0089}", "\u{F089E}", "\u{F008A}", "\u{F008B}", "\u{F0085}"]
			: ["\u{F008E}", "\u{F007A}", "\u{F007B}", "\u{F007C}", "\u{F007D}", "\u{F007E}", "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0082}", "\u{F0079}"]
		const icon = icons[Math.round(percent / 10)]

		const seconds = charging ? device?.timeToFull : device?.timeToEmpty
		if (showTime && seconds > 0) return icon + " " + formatTime(seconds)
		return icon + " " + percent + "%"
	}

	MouseArea {
		anchors.fill: parent
		onClicked: root.showTime = !root.showTime
	}
}
