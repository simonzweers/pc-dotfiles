// Wallpaper.qml
// desktop background drawn from command output instead of an image:
// fastfetch in the top left corner with a random cowsay fortune (like the hyprlock screen) at the bottom under it,
// inxi hardware info on the right half, or under fastfetch on narrow screens,
// and a random wallpaper as coloured ascii art in the bottom right corner, or above the fortune on narrow screens.
// everything is blurred while the monitor's workspace has windows on it
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
	id: root

	property string logo: ""
	property string info: ""
	property string cow: ""
	property string hardware: ""
	property string art: ""

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

	// jp2a output, turning its 24-bit colour codes into font colours
	// (--color-depth=24 is needed because jp2a falls back to 16 colours without COLORTERM set)
	function styleArt(text) {
		return text.replace(/\s+$/, "").split("\n").map(line => {
			let color = Theme.fg
			return line.split(/(\x1b\[[0-9;]*m)/).map(part => {
				const rgb = part.match(/^\x1b\[38;2;(\d+);(\d+);(\d+)m$/)
				if (rgb) color = Qt.rgba(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1)
				else if (part.startsWith("\x1b")) color = Theme.fg
				else if (part) return colored(part, color)
				return ""
			}).join("")
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

	Process {
		id: artProc
		running: true
		command: ["sh", "-c", "cd ~/pc-dotfiles/dotfiles-main && jp2a --colors --color-depth=24 wallpapers/$(ls wallpapers | shuf | head -n1)"]
		stdout: StdioCollector {
			onStreamFinished: root.art = root.styleArt(text)
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

	// a new fortune and wallpaper every 10 minutes
	Timer {
		interval: 10 * 60 * 1000
		running: true
		repeat: true
		onTriggered: {
			cowProc.running = true
			artProc.running = true
		}
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

			// fastfetch doesn't leave room for inxi on the right half (e.g. a portrait monitor)
			readonly property bool narrow: fetch.width + 60 > width / 2

			// blur while the workspace shown on this monitor has windows
			readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			readonly property bool occupied: (monitor?.activeWorkspace?.toplevels.values.length ?? 0) > 0
			property real blur: occupied ? 1 : 0
			Behavior on blur { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

			Item {
				anchors.fill: parent

				// only render through the effect while blurring
				layer.enabled: wallpaper.blur > 0
				layer.effect: MultiEffect {
					blurEnabled: true
					blur: wallpaper.blur
					blurMax: 48
				}

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
					id: cow
					x: info.x
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 30
					text: root.cow
					color: Theme.gray
				}

				// inxi goes below fastfetch on narrow screens
				OutputText {
					id: hardware
					x: wallpaper.narrow ? info.x : parent.width / 2
					y: wallpaper.narrow ? fetch.y + fetch.height + 30 : wallpaper.contentTop
					textFormat: Text.StyledText
					text: root.hardware
				}

				// the ascii wallpaper goes in the bottom right corner, or above the fortune on narrow screens
				OutputText {
					x: wallpaper.narrow ? hardware.x : parent.width - width - 30
					y: wallpaper.narrow ? cow.y - height - 30 : parent.height - height - 30
					textFormat: Text.StyledText
					text: root.art
				}
			}
		}
	}
}
