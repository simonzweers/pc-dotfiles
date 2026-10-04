// MediaWidget.qml
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

BarText {
	id: root
	// the bar window this widget lives in, used to place the popup on the right screen
	required property PanelWindow bar

	readonly property var players: Mpris.players.values
	// the player picked in the popup, or the one that most recently started playing
	property MprisPlayer pickedPlayer: null
	readonly property MprisPlayer player: {
		if (players.includes(pickedPlayer)) return pickedPlayer
		return players.find(p => p.isPlaying) ?? players[0] ?? null
	}

	// a player that starts playing takes over the widget, e.g. starting a video while spotify is selected
	Instantiator {
		model: Mpris.players

		Connections {
			required property MprisPlayer modelData
			target: modelData

			function onIsPlayingChanged() {
				if (modelData.isPlaying) root.pickedPlayer = modelData
			}
		}
	}

	visible: player !== null
	width: Math.min(implicitWidth, 260)
	elide: Text.ElideRight
	color: player?.isPlaying ? Theme.fg : Theme.gray

	text: {
		if (!player) return ""
		const title = player.trackTitle || player.identity
		const label = player.trackArtist ? player.trackArtist + " - " + title : title
		return (player.isPlaying ? "\u{F03E4}" : "\u{F040A}") + " " + label
	}

	// click to open the media menu, right click to play/pause, middle click for the next track
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		onClicked: mouse => {
			if (mouse.button === Qt.RightButton) {
				if (root.player?.canTogglePlaying) root.player.togglePlaying()
			} else if (mouse.button === Qt.MiddleButton) {
				if (root.player?.canGoNext) root.player.next()
			} else {
				popup.visible = !popup.visible
			}
		}
	}

	MediaPopup {
		id: popup
		bar: root.bar
		anchorItem: root
		player: root.player
		players: root.players
		onPlayerPicked: p => root.pickedPlayer = p
	}
}
