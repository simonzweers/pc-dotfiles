// NotificationPopups.qml
// notification popups in the top right corner of the focused monitor
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

PanelWindow {
	id: root

	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	visible: NotificationService.notifications.values.length > 0
	color: "transparent"

	anchors {
		top: true
		right: true
	}

	// sits below the bar, with the same gap as hyprland's gaps_out
	margins {
		top: 10
		right: 10
	}

	// don't push windows out of the way
	exclusionMode: ExclusionMode.Normal
	exclusiveZone: 0

	implicitWidth: 360
	implicitHeight: column.implicitHeight

	Column {
		id: column
		width: parent.width
		spacing: 10

		Repeater {
			model: NotificationService.notifications

			Rectangle {
				id: popup
				required property Notification modelData
				readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
				readonly property string icon: {
					const icon = modelData.appIcon
					if (icon.startsWith("/") || icon.includes("://")) return icon
					return icon ? Quickshell.iconPath(icon, true) : ""
				}

				width: column.width
				implicitHeight: content.implicitHeight + 30
				radius: 15
				color: Theme.bg
				border.color: critical ? Theme.red : hover.containsMouse ? Theme.yellow : Theme.bg2
				border.width: 2

				// critical notifications stay until dismissed; hovering pauses the timeout
				Timer {
					interval: popup.modelData.expireTimeout > 0 ? popup.modelData.expireTimeout * 1000 : 5000
					running: !popup.critical && !hover.containsMouse
					onTriggered: popup.modelData.expire()
				}

				// click anywhere on the popup to dismiss it
				MouseArea {
					id: hover
					anchors.fill: parent
					hoverEnabled: true
					onClicked: popup.modelData.dismiss()
				}

				RowLayout {
					id: content
					anchors.fill: parent
					anchors.margins: 15
					spacing: 12

					Image {
						Layout.alignment: Qt.AlignTop
						Layout.preferredWidth: 48
						Layout.preferredHeight: 48
						visible: source != ""
						source: popup.modelData.image || popup.icon
						sourceSize.width: 48
						sourceSize.height: 48
						fillMode: Image.PreserveAspectFit
					}

					ColumnLayout {
						Layout.fillWidth: true
						Layout.alignment: Qt.AlignTop
						spacing: 4

						BarText {
							Layout.fillWidth: true
							visible: text !== ""
							text: popup.modelData.appName
							color: Theme.gray
							font.pixelSize: 11
							elide: Text.ElideRight
						}

						BarText {
							Layout.fillWidth: true
							text: popup.modelData.summary
							color: popup.critical ? Theme.red : Theme.yellow
							font.bold: true
							wrapMode: Text.Wrap
						}

						BarText {
							Layout.fillWidth: true
							visible: text !== ""
							text: popup.modelData.body
							textFormat: Text.StyledText
							linkColor: Theme.blue
							wrapMode: Text.Wrap
							maximumLineCount: 6
							elide: Text.ElideRight
							onLinkActivated: link => Qt.openUrlExternally(link)
						}

						// buttons for notification actions, e.g. "Reply" or "Open"
						Flow {
							Layout.fillWidth: true
							Layout.topMargin: 4
							visible: popup.modelData.actions.length > 0
							spacing: 6

							Repeater {
								model: popup.modelData.actions

								Rectangle {
									id: action
									required property NotificationAction modelData

									width: actionLabel.implicitWidth + 20
									height: 24
									radius: 12
									color: actionMouse.containsMouse ? Theme.bg2 : Theme.bg1

									BarText {
										id: actionLabel
										anchors.centerIn: parent
										text: action.modelData.text
									}

									MouseArea {
										id: actionMouse
										anchors.fill: parent
										hoverEnabled: true
										onClicked: action.modelData.invoke()
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
