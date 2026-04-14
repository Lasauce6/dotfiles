pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Assets.Matugen
import qs.Services

Singleton {
	id: root

	property string dynamicConfigPath: Settings.isLoaded ? Settings.cacheDir + "matugen.dynamic.toml" : ""
	
	// Concurrency protection
	property bool generationInProgress: false
	property bool generationQueued: false
	
	// Timeout configuration
	property int generationTimeout: 30000 // 30 seconds
	
	// Error tracking
	property string lastError: ""
	
	// Signals for external listeners
	signal generationStarted()
	signal generationSucceeded()
	signal generationFailed(string errorMessage)
	signal generationTimedOut()

	// External state management
	Connections {
		target: WallpaperService
		function onWallpaperChanged(screenName, path) {
			// Only detect changes on main screen
			if (screenName === Screen.name && Settings.data.colorSchemes.useWallpaperColors) {
				generateFromWallpaper()
			}
		}
	}

	Connections {
		target: Settings.data.colorSchemes
		function onDarkModeChanged() {
			Logger.log("Matugen", "Detected dark mode change")
			if (Settings.data.colorSchemes.useWallpaperColors) {
				MatugenService.generateFromWallpaper()
			}
		}
	}

	// --------------------------------
	function init() {
		// does nothing but ensure the singleton is created
		// do not remove
		Logger.log("Matugen", "Service started")
	}

	// Build TOML content based on settings
	function buildConfigToml() {
		return Matugen.buildConfigToml()
	}

	// Helper function for shell escaping
	function shellEscape(str) {
		return "'" + str.replace(/'/g, "'\\''") + "'"
	}

	// Generate colors using current wallpaper and settings
	function generateFromWallpaper() {
		// Check if already generating
		if (generationInProgress) {
			generationQueued = true
			Logger.log("Matugen", "Generation queued (already in progress)")
			return
		}

		Logger.log("Matugen", "Generating from wallpaper on screen:", Screen.name)
		
		// Get wallpaper path
		var wpPath = WallpaperService.getWallpaper(Screen.name)
		if (wpPath === "") {
			lastError = "No wallpaper was found"
			Logger.error("Matugen", lastError)
			generationFailed(lastError)
			if (Settings.isLoaded) {
				ToastService.showWarning("Matugen", lastError)
			}
			return
		}

		// Check if matugen binary exists
		matugenCheckProcess.command = ["which", "matugen"]
		matugenCheckProcess.running = true
	}

	// Process to check if matugen exists
	Process {
		id: matugenCheckProcess
		running: false

		onExited: function(exitCode, exitStatus) {
			if (exitCode !== 0) {
				root.lastError = "matugen binary not found - please install matugen"
				Logger.error("Matugen", root.lastError)
				root.generationFailed(root.lastError)
				if (Settings.isLoaded) {
					ToastService.showWarning("Matugen", "Binary not found. Please install matugen")
				}
				return
			}

			// matugen exists, proceed with generation
			root.generationStarted()
			root.lastError = ""
			
			var wpPath = WallpaperService.getWallpaper(Screen.name)
			var wp = root.shellEscape(wpPath)
			
			var content = root.buildConfigToml()
			var mode = Settings.data.colorSchemes.darkMode ? "dark" : "light"
			var pathEsc = root.shellEscape(root.dynamicConfigPath)
			var extraRepo = root.shellEscape(Quickshell.shellDir + "/Assets/Matugen/")
			var extraUser = root.shellEscape(Settings.configDir + "matugen.d")

			// Build the main script
			var script = "cat > " + pathEsc + " << 'EOF'\n" + content + "EOF\n" + "for d in " + extraRepo + " " + extraUser
			+ "; do\n" + "  if [ -d \"$d\" ]; then\n"
			+ "    for f in \"$d\"/*.toml; do\n" + "      [ -f \"$f\" ] && { echo; echo \"# extra: $f\"; cat \"$f\"; } >> " + pathEsc + "\n"
			+ "    done\n" + "  fi\n" + "done\n" + "matugen image " + wp + " --config " + pathEsc + " --mode " + mode

			// Add user config execution if enabled
			if (Settings.data.matugen.enableUserTemplates) {
				var userConfigPath = root.shellEscape(Quickshell.env("HOME") + "/.config/matugen/config.toml")
				script += "\n# Execute user config if it exists\nif [ -f " + userConfigPath + " ]; then\n"
				script += "  matugen image " + wp + " --config " + userConfigPath + " --mode " + mode + "\n"
				script += "fi"
			}

			script += "\n"
			generateProcess.command = ["bash", "-lc", script]
			generateProcess.running = true
			generationTimeoutTimer.start()
		}

		stdout: StdioCollector {}
		stderr: StdioCollector {}
	}

	// Timeout timer
	Timer {
		id: generationTimeoutTimer
		interval: generationTimeout
		repeat: false
		onTriggered: {
			if (generateProcess.running) {
				Logger.warn("Matugen", "Timeout after 30s, killing process")
				generateProcess.kill()
				generationInProgress = false
				generationQueued = false
				root.lastError = "Generation timed out after 30 seconds"
				root.generationTimedOut()
				if (Settings.isLoaded) {
					ToastService.showWarning("Matugen", "Generation timed out")
				}
			}
		}
	}

	// Main generation process
	Process {
		id: generateProcess
		workingDirectory: Quickshell.shellDir
		running: false

		onExited: function(exitCode, exitStatus) {
			generationTimeoutTimer.stop()
			
			if (exitCode === 0) {
				Logger.log("Matugen", "Generation completed successfully")
				root.lastError = ""
				root.generationSucceeded()
				if (Settings.isLoaded) {
					ToastService.showNotice("Matugen", "Colors generated successfully")
				}
			} else {
				var errorMsg = stderr.text !== "" ? stderr.text : "Generation failed with exit code " + exitCode
				Logger.error("Matugen", "Generation failed:", errorMsg)
				root.lastError = errorMsg
				root.generationFailed(errorMsg)
				if (Settings.isLoaded) {
					ToastService.showWarning("Matugen", "Generation failed")
				}
			}

			root.generationInProgress = false
			
			// Process queued request if any
			if (root.generationQueued) {
				root.generationQueued = false
				Logger.log("Matugen", "Processing queued generation request")
				Qt.callLater(root.generateFromWallpaper)
			}
		}

		stderr: StdioCollector {}
		stdout: StdioCollector {}
	}

	// No separate writer; the write happens inline via bash heredoc
}
