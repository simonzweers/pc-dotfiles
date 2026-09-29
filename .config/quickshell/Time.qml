pragma Singleton
// Time.qml
// the pragma above makes this type a Singleton (it must be the first line)

import Quickshell
import QtQuick

// your singletons should always have Singleton as the type
Singleton {
	id: root
	readonly property string time: {
		Qt.formatDateTime(clock.date, "ddd MMM d HH:mm:ss t yyyy")
	}

	SystemClock {
		id:clock
		precision: SystemClock.Seconds
	}
}
