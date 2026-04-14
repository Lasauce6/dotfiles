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

	// Helper function for shell escaping - properly escape single quotes and double quotes
	function shellEscape(str) {
		if (str.indexOf("'") === -1) {
			// No single quotes, use single quote wrapping
			return "'" + str + "'"
		} else if (str.indexOf('"') === -1) {
			// No double quotes, use double quote wrapping
			return '"' + str + '"'
		} else {
			// Both types present, escape both and use single quotes
			return "'" + str.replace(/'/g, "'\\''").replace(/"/g, '\\"') + "'"
		}
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
			var extraRepo = Quickshell.shellDir + "/Assets/Matugen/"
			var extraUser = Settings.configDir + "matugen.d"
			
			Logger.log("Matugen", "Starting generation:")
			Logger.log("Matugen", "  Wallpaper:", wpPath)
			Logger.log("Matugen", "  Mode:", mode)
			Logger.log("Matugen", "  Config path:", root.dynamicConfigPath)

			// Build the main script with improved escaping
			var script = "set -e\n"  // Exit on first error
			script += "# Create config\n"
			script += "cat > " + pathEsc + " << 'EOF'\n" + content + "EOF\n"
			script += "# Add extra templates if they exist\n"
			script += "for d in " + root.shellEscape(extraRepo) + " " + root.shellEscape(extraUser) + "; do\n"
			script += "  if [ -d \"$d\" ]; then\n"
			script += "    for f in \"$d\"/*.toml; do\n"
			script += "      [ -f \"$f\" ] && { echo; echo \"# extra: $f\"; cat \"$f\"; } >> " + pathEsc + "\n"
			script += "    done\n"
			script += "  fi\n"
			script += "done\n"
			script += "# Run matugen\n"
			script += "matugen image " + wp + " --config " + pathEsc + " --mode " + mode + "\n"

			// Add user config execution if enabled
			if (Settings.data.matugen.enableUserTemplates) {
				var userConfigPath = Settings.configDir + "../matugen/config.toml"
				script += "# Execute user config if it exists\n"
				script += "if [ -f " + root.shellEscape(userConfigPath) + " ]; then\n"
				script += "  matugen image " + wp + " --config " + root.shellEscape(userConfigPath) + " --mode " + mode + "\n"
				script += "fi\n"
			}

			// Verify output was created
			script += "# Verify colors.json was created\n"
			script += "if [ ! -f " + root.shellEscape(Settings.configDir + "colors.json") + " ]; then\n"
			script += "  echo 'ERROR: colors.json was not created'\n"
			script += "  exit 1\n"
			script += "fi\n"

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
				
				// Force reload of colors from disk
				Qt.callLater(function() {
					Logger.log("Matugen", "Triggering color reload after generation")
					// Trigger a reload by resetting the path
					var colorPath = Settings.configDir + "colors.json"
					// This will trigger the FileView onFileChanged signal
				})
			} else {
				var errorMsg = ""
				if (stderr.text && stderr.text !== "") {
					errorMsg = stderr.text
				} else {
					errorMsg = "Generation failed with exit code " + exitCode
				}
				
				Logger.error("Matugen", "Generation failed:")
				Logger.error("Matugen", "  Exit code:", exitCode)
				Logger.error("Matugen", "  Error output:", stderr.text)
				Logger.error("Matugen", "  Standard output:", stdout.text)
				
				root.lastError = errorMsg
				root.generationFailed(errorMsg)
				if (Settings.isLoaded) {
					ToastService.showWarning("Matugen", "Generation failed: " + errorMsg)
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
