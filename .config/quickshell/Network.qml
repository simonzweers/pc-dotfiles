pragma Singleton
// Network.qml
// network state and actions, via NetworkManager's nmcli

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	property string type: ""       // "ethernet", "wifi", or "" when offline
	property string connection: "" // name of the active connection
	property int signal: 0         // wifi signal strength in percent
	property bool wifiEnabled: true
	property var networks: []      // [{ ssid, signal, secure, active, saved }]
	property var savedConnections: []
	property bool busy: false
	property string error: ""

	function refresh() {
		statusProc.running = true
		radioProc.running = true
		savedProc.running = true
		wifiProc.command = ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "no"]
		wifiProc.running = true
	}

	function scan() {
		wifiProc.command = ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "yes"]
		wifiProc.running = true
	}

	function setWifiEnabled(on) {
		run(["nmcli", "radio", "wifi", on ? "on" : "off"])
	}

	function connect(ssid, password) {
		if (savedConnections.includes(ssid))
			run(["nmcli", "connection", "up", "id", ssid])
		else if (password)
			run(["nmcli", "device", "wifi", "connect", ssid, "password", password])
		else
			run(["nmcli", "device", "wifi", "connect", ssid])
	}

	function disconnect(name) {
		run(["nmcli", "connection", "down", "id", name])
	}

	function openSettings() {
		Quickshell.execDetached(["ghostty", "-e", "nmtui"])
	}

	function run(command) {
		error = ""
		busy = true
		actionProc.command = command
		actionProc.running = true
	}

	// split a line of `nmcli -t` output, where literal colons are escaped as "\:"
	function splitTerse(line) {
		const fields = []
		let current = ""
		for (let i = 0; i < line.length; i++) {
			const c = line[i]
			if (c === "\\" && i + 1 < line.length) {
				current += line[++i]
			} else if (c === ":") {
				fields.push(current)
				current = ""
			} else {
				current += c
			}
		}
		fields.push(current)
		return fields
	}

	function lines(text) {
		return text.split("\n").filter(l => l.length > 0).map(splitTerse)
	}

	Process {
		id: statusProc
		command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
		stdout: StdioCollector {
			onStreamFinished: {
				// devices are listed in priority order, so the first connected one is the one in use
				const active = root.lines(text).find(([type, state]) => (type === "ethernet" || type === "wifi") && state === "connected")
				root.type = active ? active[0] : ""
				root.connection = active ? active[2] : ""
			}
		}
	}

	Process {
		id: radioProc
		command: ["nmcli", "radio", "wifi"]
		stdout: StdioCollector {
			onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
		}
	}

	Process {
		id: savedProc
		command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
		stdout: StdioCollector {
			onStreamFinished: root.savedConnections = root.lines(text).filter(([, type]) => type === "802-11-wireless").map(([name]) => name)
		}
	}

	Process {
		id: wifiProc
		stdout: StdioCollector {
			onStreamFinished: {
				// one entry per ssid, keeping the strongest access point
				const bySsid = {}
				for (const [inUse, signal, security, ssid] of root.lines(text)) {
					if (!ssid) continue
					const network = {
						ssid,
						signal: Number(signal),
						secure: security !== "" && security !== "--",
						active: inUse === "*",
						saved: root.savedConnections.includes(ssid),
					}
					const existing = bySsid[ssid]
					if (!existing || network.active || (!existing.active && network.signal > existing.signal))
						bySsid[ssid] = network
				}
				const networks = Object.values(bySsid).sort((a, b) => b.active - a.active || b.signal - a.signal)
				root.networks = networks
				root.signal = networks.find(n => n.active)?.signal ?? 0
			}
		}
	}

	Process {
		id: actionProc
		// nmcli only writes to stderr when something went wrong
		stderr: StdioCollector {
			onStreamFinished: root.error = text.trim()
		}
		onExited: {
			root.busy = false
			root.refresh()
		}
	}

	// refresh whenever NetworkManager reports a change
	Process {
		command: ["nmcli", "monitor"]
		running: true
		stdout: SplitParser {
			onRead: refreshDelay.restart()
		}
	}

	Timer {
		id: refreshDelay
		interval: 500
		onTriggered: root.refresh()
	}

	// keep the wifi signal strength up to date
	Timer {
		interval: 10000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: root.refresh()
	}
}
