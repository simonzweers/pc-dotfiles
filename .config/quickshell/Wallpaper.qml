// Wallpaper.qml
// desktop background drawn from command output instead of an image:
// fastfetch in the top left corner with a random cowsay fortune (like the hyprlock screen) at the bottom under it,
// inxi hardware info on the right half, or under fastfetch on narrow screens
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
	id: root

	property string logo: ""
	property string info: ""
	property string cow: ""
	property string hardware: ""

	// strip terminal colour codes and trailing blank lines
	function clean(text) {
		return text.replace(/\x1b\[[0-9;]*m/g, "").replace(/\s+$/, "")
	}

	function htmlEscape(text) {
		return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/ /g, "&nbsp;")
	}

	function colored(text, color) {
		return `<font color="${color}">${htmlEscape(text)}</font>`
	}

	// fastfetch info with coloured keys, the same way it looks in the terminal
	function styleInfo(text) {
		// everything after the first blank line is the colour palette, which needs escape codes
		const lines = clean(text).split("\n\n")[0].split("\n")
		return lines.map((line, i) => {
			if (i === 0) {
				const [user, host] = line.split("@")
				return colored(user, Theme.yellow) + colored("@", Theme.fg) + colored(host, Theme.yellow)
			}
			const sep = line.indexOf(": ")
			if (sep < 0) return colored(line, Theme.gray)
			return colored(line.slice(0, sep + 1), Theme.yellow) + htmlEscape(line.slice(sep + 1))
		}).join("<br>")
	}

	// inxi with section headers and keys coloured, like inxi's own colour output
	function styleHardware(text) {
		return clean(text).split("\n").map(line => {
			if (!line.startsWith(" ")) return colored(line, Theme.yellow)
			return line.split(/( +)/).map(part => part.endsWith(":") ? colored(part, Theme.aqua) : htmlEscape(part)).join("")
		}).join("<br>")
	}

	Process {
		id: logoProc
		running: true
		command: ["fastfetch", "--pipe", "--structure", "none"]
		stdout: StdioCollector {
			onStreamFinished: root.logo = root.clean(text)
		}
	}

	Process {
		id: infoProc
		running: true
		command: ["fastfetch", "--pipe", "--logo", "none"]
		stdout: StdioCollector {
			onStreamFinished: root.info = root.styleInfo(text)
		}
	}

	Process {
		id: cowProc
		running: true
		command: ["sh", "-c", "cowsay -f $(cowsay -l | tail -n +2 | tr ' ' '\\n' | shuf -n1) \"$(fortune -s -n 200)\""]
		stdout: StdioCollector {
			onStreamFinished: root.cow = root.clean(text)
		}
	}

	// cpu, gpu and memory; -y sets the line width so it wraps to fit half the screen
	Process {
		id: hardwareProc
		running: true
		command: ["inxi", "-CGm", "-c0", "-y", "90"]
		stdout: StdioCollector {
			onStreamFinished: root.hardware = root.styleHardware(text)
		}
	}

	// keep uptime, memory usage and friends current
	Timer {
		interval: 60 * 1000
		running: true
		repeat: true
		onTriggered: {
			infoProc.running = true
			hardwareProc.running = true
		}
	}

	// a new fortune every 10 minutes
	Timer {
		interval: 10 * 60 * 1000
		running: true
		repeat: true
		onTriggered: cowProc.running = true
	}

	component OutputText: Text {
		font.family: "CaskaydiaCove Nerd Font"
		font.pixelSize: 16
		color: Theme.fg
	}

	Variants {
		model: Quickshell.screens

		PanelWindow {
			id: wallpaper
			required property var modelData
			screen: modelData

			anchors {
				top: true
				bottom: true
				left: true
				right: true
			}

			WlrLayershell.layer: WlrLayer.Background
			WlrLayershell.namespace: "quickshell-wallpaper"
			exclusionMode: ExclusionMode.Ignore
			color: Theme.bg0

			// below the floating bar
			readonly property int contentTop: 70

			// the logo touches the left edge of the screen so it looks like it's sticking out
			Row {
				id: fetch
				x: 0
				y: wallpaper.contentTop
				spacing: 30

				OutputText {
					text: root.logo
					color: Theme.aqua
				}

				OutputText {
					id: info
					textFormat: Text.StyledText
					text: root.info
				}
			}

			OutputText {
				x: info.x
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 30
				text: root.cow
				color: Theme.gray
			}

			// fastfetch doesn't leave room for inxi on the right half (e.g. a portrait monitor)
			readonly property bool narrow: fetch.width + 60 > width / 2

			// inxi goes below fastfetch on narrow screens
			OutputText {
				x: wallpaper.narrow ? info.x : parent.width / 2
				y: wallpaper.narrow ? fetch.y + fetch.height + 30 : wallpaper.contentTop
				textFormat: Text.StyledText
				text: root.hardware
			}
		}
	}
}
