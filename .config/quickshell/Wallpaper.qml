// Wallpaper.qml
// desktop background drawn from command output instead of an image:
// fastfetch on the left, a random cowsay fortune (like the hyprlock screen) on the right
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
	id: root

	property string logo: ""
	property string info: ""
	property string cow: ""

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

	// keep uptime and friends current
	Timer {
		interval: 60 * 1000
		running: true
		repeat: true
		onTriggered: infoProc.running = true
	}

	// a new fortune every few minutes
	Timer {
		interval: 5 * 60 * 1000
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
			color: Theme.bg

			Row {
				anchors.left: parent.left
				anchors.leftMargin: parent.width * 0.08
				anchors.verticalCenter: parent.verticalCenter
				spacing: 30

				OutputText {
					text: root.logo
					color: Theme.aqua
				}

				OutputText {
					textFormat: Text.StyledText
					text: root.info
				}
			}

			OutputText {
				anchors.right: parent.right
				anchors.rightMargin: parent.width * 0.08
				anchors.verticalCenter: parent.verticalCenter
				text: root.cow
				color: Theme.gray
			}
		}
	}
}
