// MediaPopup.qml
// dropdown with the current track, seek bar and playback controls, plus a player picker
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

DropdownWindow {
	id: popup
	implicitWidth: 380

	required property MprisPlayer player
	required property var players
	signal playerPicked(MprisPlayer player)

	readonly property real length: player?.length ?? 0
	readonly property bool seekable: (player?.canSeek ?? false) && (player?.positionSupported ?? false) && length > 0

	function formatTime(seconds) {
		const s = Math.max(0, Math.floor(seconds))
		const pad = n => n < 10 ? "0" + n : "" + n
		if (s >= 3600) return Math.floor(s / 3600) + ":" + pad(Math.floor(s / 60) % 60) + ":" + pad(s % 60)
		return Math.floor(s / 60) + ":" + pad(s % 60)
	}

	// mpris doesn't push position updates, so poll it while playing
	Timer {
		running: popup.visible && (popup.player?.isPlaying ?? false)
		interval: 1000
		repeat: true
		triggeredOnStart: true
		onTriggered: popup.player?.positionChanged()
	}

	// icon button for the playback controls
	component ControlButton: BarText {
		id: control
		property bool active: true
		signal clicked()

		font.pixelSize: 20
		opacity: enabled ? 1 : 0.4
		color: !active ? Theme.gray : mouse.containsMouse && enabled ? Theme.yellow : Theme.fg

		MouseArea {
			id: mouse
			anchors.fill: parent
			anchors.margins: -4
			hoverEnabled: true
			onClicked: control.clicked()
		}
	}

	// player picker, only when there's a choice
	Flow {
		Layout.fillWidth: true
		visible: popup.players.length > 1
		spacing: 6

		Repeater {
			model: popup.players

			PillButton {
				required property MprisPlayer modelData
				text: modelData.identity
				highlighted: modelData === popup.player
				onClicked: popup.playerPicked(modelData)
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true
		spacing: 12

		// album art, or a note when the player doesn't provide any
		Rectangle {
			implicitWidth: 72
			implicitHeight: 72
			radius: 8
			color: Theme.bg1

			BarText {
				anchors.centerIn: parent
				visible: art.status !== Image.Ready
				text: "\u{F075A}"
				font.pixelSize: 32
				color: Theme.gray
			}

			Image {
				id: art
				anchors.fill: parent
				source: popup.player?.trackArtUrl ?? ""
				fillMode: Image.PreserveAspectCrop
				sourceSize.width: 144
				sourceSize.height: 144
				asynchronous: true
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			spacing: 2

			BarText {
				Layout.fillWidth: true
				text: popup.player?.trackTitle || popup.player?.identity || "Nothing playing"
				font.bold: true
				elide: Text.ElideRight
			}

			BarText {
				Layout.fillWidth: true
				visible: text !== ""
				text: popup.player?.trackArtist ?? ""
				color: Theme.aqua
				elide: Text.ElideRight
			}

			BarText {
				Layout.fillWidth: true
				visible: text !== ""
				text: popup.player?.trackAlbum ?? ""
				color: Theme.gray
				elide: Text.ElideRight
			}
		}
	}

	// click or drag to seek
	RowLayout {
		Layout.fillWidth: true
		visible: popup.length > 0
		spacing: 10

		BarText {
			text: popup.formatTime(popup.player?.position ?? 0)
			color: Theme.gray
		}

		Item {
			id: seekBar
			Layout.fillWidth: true
			implicitHeight: 16

			readonly property real progress: popup.length > 0 ? Math.min((popup.player?.position ?? 0) / popup.length, 1) : 0

			function seek(x) {
				if (popup.seekable) popup.player.position = Math.max(0, Math.min(1, x / width)) * popup.length
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width
				height: 6
				radius: 3
				color: Theme.bg2

				Rectangle {
					width: parent.width * seekBar.progress
					height: parent.height
					radius: 3
					color: Theme.aqua
				}
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				visible: popup.seekable
				x: parent.width * seekBar.progress - width / 2
				width: 14
				height: 14
				radius: 7
				color: Theme.fg
			}

			MouseArea {
				anchors.fill: parent
				enabled: popup.seekable
				onPressed: mouse => seekBar.seek(mouse.x)
				onPositionChanged: mouse => seekBar.seek(mouse.x)
			}
		}

		BarText {
			text: popup.formatTime(popup.length)
			color: Theme.gray
		}
	}

	RowLayout {
		Layout.alignment: Qt.AlignHCenter
		spacing: 24

		ControlButton {
			visible: popup.player?.shuffleSupported ?? false
			text: popup.player?.shuffle ? "\u{F049D}" : "\u{F049E}"
			active: popup.player?.shuffle ?? false
			font.pixelSize: 16
			onClicked: popup.player.shuffle = !popup.player.shuffle
		}

		ControlButton {
			text: "\u{F04AE}"
			enabled: popup.player?.canGoPrevious ?? false
			onClicked: popup.player.previous()
		}

		ControlButton {
			text: popup.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}"
			enabled: popup.player?.canTogglePlaying ?? false
			font.pixelSize: 28
			onClicked: popup.player.togglePlaying()
		}

		ControlButton {
			text: "\u{F04AD}"
			enabled: popup.player?.canGoNext ?? false
			onClicked: popup.player.next()
		}

		// cycles off -> playlist -> track
		ControlButton {
			visible: popup.player?.loopSupported ?? false
			readonly property int loop: popup.player?.loopState ?? MprisLoopState.None
			text: loop === MprisLoopState.Track ? "\u{F0458}" : loop === MprisLoopState.Playlist ? "\u{F0456}" : "\u{F0457}"
			active: loop !== MprisLoopState.None
			font.pixelSize: 16
			onClicked: popup.player.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
				: loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
		}
	}
}
