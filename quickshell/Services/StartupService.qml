pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Services

Singleton {
	id: root

	// Initialize service
	function init() {
		Logger.log("StartupService", "Service initialized")
		
		// Connect to Settings loaded signal
		Settings.settingsLoaded.connect(onSettingsLoaded)
		
		// If settings are already loaded (edge case during hot reload)
		if (Settings.isLoaded) {
			Qt.callLater(onSettingsLoaded)
		}
	}

	function onSettingsLoaded() {
		Logger.log("StartupService", "Settings loaded, checking startup configuration...")
		
		// Get configuration from settings.json
		const autoLockEnabled = Settings.data.startup?.autoLock ?? true
		
		Logger.log("StartupService", "Auto-lock configured as:", autoLockEnabled)
		
		if (autoLockEnabled && PanelService.lockScreen) {
			Logger.log("StartupService", "⚠️  Activating LockScreen at startup")
			PanelService.lockScreen.active = true
		}
	}
}
