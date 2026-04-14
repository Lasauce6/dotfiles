import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Launcher
import qs.Modules.Background
import qs.Modules.Bar
import qs.Modules.Bar.Extras
import qs.Modules.BluetoothPanel
import qs.Modules.Calendar
import qs.Modules.Dock
import qs.Modules.IPC
import qs.Modules.LockScreen
import qs.Modules.Notification
import qs.Modules.SettingsPanel
import qs.Modules.PowerPanel
import qs.Modules.SidePanel
import qs.Modules.Toast
import qs.Modules.WiFiPanel
import qs.Modules.ArchUpdaterPanel
import qs.Services

ShellRoot {
	id: shellRoot

	Background {}
	Overview {}
	ScreenCorners {}
	Bar {}
	Dock {}

	Notification {
		id: notification
	}

	LockScreen {
		id: lockScreen
	}

	ToastOverlay {}

	IPCManager {}

	// ------------------------------
	// All the NPanels
	Launcher {
		id: launcherPanel
		objectName: "launcherPanel"
	}

	SidePanel {
		id: sidePanel
		objectName: "sidePanel"
	}

	Calendar {
		id: calendarPanel
		objectName: "calendarPanel"
	}

	SettingsPanel {
		id: settingsPanel
		objectName: "settingsPanel"
	}

	NotificationHistoryPanel {
		id: notificationHistoryPanel
		objectName: "notificationHistoryPanel"
	}

	PowerPanel {
		id: powerPanel
		objectName: "powerPanel"
	}

	WiFiPanel {
		id: wifiPanel
		objectName: "wifiPanel"
	}

	BluetoothPanel {
		id: bluetoothPanel
		objectName: "bluetoothPanel"
	}

	ArchUpdaterPanel {
		id: archUpdaterPanel
		objectName: "archUpdaterPanel"
	}

	Component.onCompleted: {
		// Initialize all services in dependency order
		// Each service should be capable of self-initialization
		initializeServices()
	}

	// Centralized service initialization
	function initializeServices() {
		try {
			// Save a reference to lockScreen for security services
			if (typeof PanelService !== 'undefined') {
				PanelService.lockScreen = lockScreen
			}

			// Initialize location service early for weather/sunrise time
			if (typeof LocationService !== 'undefined') {
				LocationService.init()
			}

			// Apply night light settings
			if (typeof NightLightService !== 'undefined') {
				NightLightService.apply()
			}

			// Initialize startup/auto-lock service
			if (typeof StartupService !== 'undefined') {
				StartupService.init()
			}

			Logger.log("Shell", "Services initialized successfully")
		} catch (error) {
			Logger.error("Shell", "Error during service initialization:", error.toString())
		}
	}
}
