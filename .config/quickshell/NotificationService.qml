pragma Singleton
// NotificationService.qml
// makes quickshell the notification daemon (org.freedesktop.Notifications)

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
	// notifications currently on screen; they leave this list when they expire or are dismissed
	readonly property var notifications: server.trackedNotifications

	NotificationServer {
		id: server
		keepOnReload: true
		actionsSupported: true
		bodySupported: true
		bodyMarkupSupported: true
		bodyHyperlinksSupported: true
		imageSupported: true

		// notifications are dropped unless tracked
		onNotification: notification => notification.tracked = true
	}
}
