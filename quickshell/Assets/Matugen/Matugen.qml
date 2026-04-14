pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Central place to define which templates we generate and where they write.
// Users can extend it by dropping additional templates into:
//  - Assets/Matugen/templates/
//  - ~/.config/matugen/ (when enableUserTemplates is true)
Singleton {
	id: root

	// Build the base TOML using current settings
	function buildConfigToml() {
		var lines = []
		lines.push("[config]")

		lines.push("[templates.quickshell]")
		lines.push('input_path = "' + Quickshell.shellDir + '/Assets/Matugen/templates/quickshell.json"')
		lines.push('output_path = "' + Settings.configDir + 'colors.json"')

		if (Settings.data.matugen.gtk4) {
			lines.push("\n[templates.gtk4]")
			lines.push('input_path = "' + Quickshell.shellDir + '/Assets/Matugen/templates/gtk4.css"')
			lines.push('output_path = "~/.config/gtk-4.0/gtk.css"')
		}
		if (Settings.data.matugen.gtk3) {
			lines.push("\n[templates.gtk3]")
			lines.push('input_path = "' + Quickshell.shellDir + '/Assets/Matugen/templates/gtk3.css"')
			lines.push('output_path = "~/.config/gtk-3.0/gtk.css"')
		}
		if (Settings.data.matugen.qt6) {
			lines.push("\n[templates.qt6]")
			lines.push('input_path = "' + Quickshell.shellDir + '/Assets/Matugen/templates/qtct.conf"')
			lines.push('output_path = "~/.config/qt6ct/colors/quickshell.conf"')
		}
		if (Settings.data.matugen.qt5) {
			lines.push("\n[templates.qt5]")
			lines.push('input_path = "' + Quickshell.shellDir + '/Assets/Matugen/templates/qtct.conf"')
			lines.push('output_path = "~/.config/qt5ct/colors/quickshell.conf"')
		}
		if (Settings.data.matugen.kitty) {
			lines.push("\n[templates.kitty]")
			lines.push('input_path = "' + Quickshell.shellDir + '/Assets/Matugen/templates/kitty.conf"')
			lines.push('output_path = "~/.config/kitty/themes/quickshell.conf"')
			lines.push("post_hook   = 'kitty +kitten themes --reload-in=all quickshell'")
		}
		if (Settings.data.matugen.hyprland) {
			lines.push("\n[templates.hyprland]")
			lines.push('input_path = "' + Quickshell.shellDir + '/Assets/Matugen/templates/hyprland.conf"')
			lines.push('output_path = "~/.config/hypr/theme/colors-hyprland.conf"')
		}

		return lines.join("\n") + "\n"
	}
}
