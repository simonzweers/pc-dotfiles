// Launcher.qml
// app launcher, command runner and window switcher on the focused monitor
// toggle with `qs ipc call launcher toggle <apps|run|windows>`
// type to filter, up/down or ctrl+j/k to move, enter to pick, tab to switch mode, escape to close
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
	id: root
	property bool shown: false
	property string mode: "apps"
	property string query: ""
	// executables on $PATH, loaded the first time run mode is opened
	property var commands: []

	readonly property var modes: [
		{ id: "apps", name: "Apps", icon: "\u{F003B}" },
		{ id: "run", name: "Run", icon: "\u{F018D}" },
		{ id: "windows", name: "Windows", icon: "\u{F05B6}" },
	]

	function show(newMode: string): void {
		mode = modes.some(m => m.id === newMode) ? newMode : "apps"
		query = ""
		shown = true
	}

	function cycleMode(step: int): void {
		const index = modes.findIndex(m => m.id === mode)
		mode = modes[(index + step + modes.length) % modes.length].id
	}

	// higher is a better match, -1 is no match
	function score(text: string, q: string): int {
		if (!text) return -1
		const t = text.toLowerCase()
		if (t === q) return 100
		if (t.startsWith(q)) return 80
		const i = t.indexOf(q)
		if (i > 0 && /[\s\-_.]/.test(t[i - 1])) return 60
		if (i >= 0) return 40
		// all letters in order, e.g. "ffx" for firefox
		let j = 0
		for (const c of t) if (c === q[j]) j++
		return j === q.length ? 10 : -1
	}

	function filter(items: var): var {
		const q = query.trim().toLowerCase()
		if (!q) return items
		return items
			.map(item => ({ item, score: Math.max(...item.search.map((text, i) => {
				const s = score(text, q)
				return s < 0 ? -1 : s - i * 5
			})) }))
			.filter(r => r.score >= 0)
			.sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name))
			.map(r => r.item)
	}

	readonly property var apps: DesktopEntries.applications.values
		.filter(e => !e.noDisplay)
		.map(e => ({
			name: e.name,
			detail: e.genericName || e.comment,
			icon: e.icon,
			search: [e.name, e.genericName, e.keywords.join(" "), e.comment],
			run: () => {
				if (e.runInTerminal)
					Quickshell.execDetached({ command: ["ghostty", "-e", ...e.command], workingDirectory: e.workingDirectory })
				else
					e.execute()
			},
		}))
		.sort((a, b) => a.name.localeCompare(b.name))

	readonly property var windows: Hyprland.toplevels.values.map(t => {
		const appId = t.wayland?.appId ?? ""
		const entry = DesktopEntries.heuristicLookup(appId)
		return {
			name: t.title || appId,
			detail: (entry?.name ?? appId) + " · workspace " + (t.workspace?.name ?? "?"),
			icon: entry?.icon ?? "",
			search: [t.title, appId, entry?.name ?? ""],
			run: () => t.wayland?.activate(),
		}
	})

	readonly property var runItems: {
		const typed = query.trim()
		const items = commands.map(c => ({
			name: c, detail: "", icon: "", search: [c],
			run: () => Quickshell.execDetached([c]),
		}))
		// anything with arguments, or not on $PATH, runs as typed through the shell
		const matches = filter(items)
		if (typed && (typed.includes(" ") || matches.length === 0))
			return [{ name: typed, detail: "Run in shell", icon: "", search: [typed], run: () => Quickshell.execDetached(["sh", "-c", typed]) }]
		return matches
	}

	readonly property var results: mode === "apps" ? filter(apps) : mode === "windows" ? filter(windows) : runItems

	function trigger(index: int): void {
		const item = results[index]
		if (!item) return
		shown = false
		item.run()
	}

	onModeChanged: {
		if (mode === "windows") Hyprland.refreshToplevels()
		if (mode === "run" && commands.length === 0) pathScan.running = true
	}

	Process {
		id: pathScan
		command: ["sh", "-c", "IFS=:; for d in $PATH; do [ -d \"$d\" ] && ls \"$d\"; done 2>/dev/null | sort -u"]
		stdout: StdioCollector {
			onStreamFinished: root.commands = text.split("\n").filter(c => c)
		}
	}

	IpcHandler {
		target: "launcher"
		function toggle(mode: string): void {
			if (root.shown && root.mode === (mode || "apps")) root.shown = false
			else root.show(mode)
		}
		function open(mode: string): void { root.show(mode) }
		function close(): void { root.shown = false }
	}

	PanelWindow {
		id: window
		visible: root.shown
		screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
		color: "transparent"

		anchors {
			top: true
			bottom: true
			left: true
			right: true
		}

		// cover the bar too, and grab the keyboard while open
		WlrLayershell.layer: WlrLayer.Overlay
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
		WlrLayershell.namespace: "quickshell-launcher"
		exclusionMode: ExclusionMode.Ignore

		onVisibleChanged: if (visible) {
			if (root.mode === "windows") Hyprland.refreshToplevels()
			if (root.mode === "run" && root.commands.length === 0) pathScan.running = true
			search.forceActiveFocus()
		}

		// dimmed backdrop, click it to close
		Rectangle {
			anchors.fill: parent
			color: Qt.rgba(0, 0, 0, 0.3)

			MouseArea {
				anchors.fill: parent
				onClicked: root.shown = false
			}
		}

		Rectangle {
			anchors.centerIn: parent
			width: Math.min(640, parent.width - 40)
			height: Math.min(480, parent.height - 40)
			radius: 15
			color: Theme.bg
			border.color: Theme.bg2
			border.width: 2

			// swallow clicks so they don't reach the backdrop
			MouseArea { anchors.fill: parent }

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 15
				spacing: 10

				// mode tabs
				Row {
					spacing: 6

					Repeater {
						model: root.modes

						PillButton {
							required property var modelData
							text: modelData.icon + "  " + modelData.name
							highlighted: root.mode === modelData.id
							onClicked: {
								root.mode = modelData.id
								search.forceActiveFocus()
							}
						}
					}
				}

				// search field
				Rectangle {
					Layout.fillWidth: true
					implicitHeight: 34
					radius: 10
					color: Theme.bg1

					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: 12
						anchors.rightMargin: 12
						spacing: 10

						BarText {
							text: "\u{F0349}"
							color: Theme.yellow
						}

						TextInput {
							id: search
							Layout.fillWidth: true
							font.family: "CaskaydiaCove Nerd Font"
							font.pixelSize: 14
							color: Theme.fg
							selectionColor: Theme.bg2
							clip: true
							text: root.query
							onTextChanged: {
								root.query = text
								list.currentIndex = 0
							}

							BarText {
								anchors.verticalCenter: parent.verticalCenter
								visible: !search.text
								text: root.mode === "apps" ? "Search apps..." : root.mode === "run" ? "Run a command..." : "Search windows..."
								color: Theme.gray
								font.pixelSize: 14
							}

							Keys.onPressed: event => {
								const ctrl = event.modifiers & Qt.ControlModifier
								const count = list.count
								if (event.key === Qt.Key_Escape) {
									root.shown = false
								} else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
									if (count) list.currentIndex = (list.currentIndex + 1) % count
								} else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
									if (count) list.currentIndex = (list.currentIndex + count - 1) % count
								} else if (event.key === Qt.Key_Tab) {
									root.cycleMode(1)
								} else if (event.key === Qt.Key_Backtab) {
									root.cycleMode(-1)
								} else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
									root.trigger(list.currentIndex)
								} else {
									return
								}
								event.accepted = true
							}
						}
					}
				}

				ListView {
					id: list
					Layout.fillWidth: true
					Layout.fillHeight: true
					clip: true
					spacing: 2
					model: root.results
					boundsBehavior: Flickable.StopAtBounds
					highlightMoveDuration: 0

					delegate: Rectangle {
						id: row
						required property var modelData
						required property int index
						readonly property bool active: ListView.isCurrentItem
						readonly property string iconSource: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""

						width: ListView.view.width
						height: 40
						radius: 8
						color: active ? Theme.bg2 : mouse.containsMouse ? Theme.bg1 : "transparent"

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: 10
							anchors.rightMargin: 10
							spacing: 12

							Item {
								implicitWidth: 24
								implicitHeight: 24

								Image {
									anchors.fill: parent
									visible: row.iconSource !== ""
									source: row.iconSource
									sourceSize: Qt.size(48, 48)
									asynchronous: true
								}

								// fallback glyph when there's no icon
								BarText {
									anchors.centerIn: parent
									visible: row.iconSource === ""
									text: root.mode === "run" ? "\u{F018D}" : "\u{F003B}"
									font.pixelSize: 18
									color: Theme.gray
								}
							}

							ColumnLayout {
								Layout.fillWidth: true
								spacing: 0

								BarText {
									Layout.fillWidth: true
									text: row.modelData.name
									color: row.active ? Theme.yellow : Theme.fg
									elide: Text.ElideRight
								}

								BarText {
									Layout.fillWidth: true
									visible: text !== ""
									text: row.modelData.detail ?? ""
									color: Theme.gray
									font.pixelSize: 11
									elide: Text.ElideRight
								}
							}
						}

						MouseArea {
							id: mouse
							anchors.fill: parent
							hoverEnabled: true
							onClicked: root.trigger(row.index)
						}
					}

					BarText {
						anchors.centerIn: parent
						visible: list.count === 0
						text: "No results"
						color: Theme.gray
					}
				}
			}
		}
	}
}
