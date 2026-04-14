pragma Singleton

import QtQuick
import Quickshell
import qs.Services

Singleton {
	id: icons

	// Cache for icon lookups to avoid repeated system calls
	property var iconCache: ({})
	property int maxCacheSize: 500

	// Simple LRU cache implementation
	function setIconCache(key, value) {
		// If cache is too large, clear oldest entries
		if (Object.keys(iconCache).length >= maxCacheSize) {
			iconCache = ({})
		}
		iconCache[key] = value
	}

	function getIconCache(key) {
		return iconCache[key]
	}

	function iconFromName(iconName, fallbackName) {
		const fallback = fallbackName || "application-x-executable"
		
		// Check cache first
		const cacheKey = "icon_" + iconName + "_" + fallback
		const cached = getIconCache(cacheKey)
		if (cached !== undefined) {
			return cached
		}

		let result = ""
		try {
			if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
				const p = Quickshell.iconPath(iconName, fallback)
				if (p && p !== "") {
					result = p
				}
			}
		} catch (e) {
			// ignore and fall back
		}

		if (result === "") {
			try {
				result = Quickshell.iconPath ? (Quickshell.iconPath(fallback, true) || "") : ""
			} catch (e2) {
				result = ""
			}
		}

		// Cache the result
		setIconCache(cacheKey, result)
		return result
	}

	// Resolve icon path for a DesktopEntries appId - safe on missing entries
	function iconForAppId(appId, fallbackName) {
		const fallback = fallbackName || "application-x-executable"
		
		if (!appId) {
			return iconFromName(fallback, fallback)
		}

		// Check cache first
		const cacheKey = "appid_" + appId + "_" + fallback
		const cached = getIconCache(cacheKey)
		if (cached !== undefined) {
			return cached
		}

		let result = ""
		try {
			if (typeof DesktopEntries === 'undefined' || !DesktopEntries.byId) {
				result = iconFromName(fallback, fallback)
			} else {
				const entry = (DesktopEntries.heuristicLookup) ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId)
				const name = entry && entry.icon ? entry.icon : ""
				result = iconFromName(name || fallback, fallback)
			}
		} catch (e) {
			result = iconFromName(fallback, fallback)
		}

		// Cache the result
		setIconCache(cacheKey, result)
		return result
	}

	// Distro logo helper (absolute path or empty string)
	function distroLogoPath() {
		try {
			return (typeof OSInfo !== 'undefined' && OSInfo.distroIconPath) ? OSInfo.distroIconPath : ""
		} catch (e) {
			return ""
		}
	}

	// Clear cache if needed (useful for memory management)
	function clearCache() {
		iconCache = ({})
	}
}
