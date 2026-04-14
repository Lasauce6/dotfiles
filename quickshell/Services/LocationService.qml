pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
	id: root

	property string locationFile: Quickshell.env("QUICKSHELL_WEATHER_FILE") || (Settings.cacheDir + "location.json")
	property int weatherUpdateFrequency: 30 * 60 // 30 minutes
	property bool isFetchingWeather: false

	readonly property alias data: adapter

	property bool coordinatesReady: false
	property string stableLatitude: ""
	property string stableLongitude: ""
	property string stableName: ""

	FileView {
		id: locationFileView
		path: locationFile

		onAdapterUpdated: saveTimer.start()

		onLoaded: {
			Logger.log("Location", "Loaded cached data")
			if (adapter.latitude !== "" && adapter.longitude !== "" && adapter.weatherLastFetch > 0) {
				root.stableLatitude = adapter.latitude
				root.stableLongitude = adapter.longitude
				root.stableName = adapter.name
				root.coordinatesReady = true
				Logger.log("Location", "Coordinates ready")
			}
			updateWeather()
		}

		onLoadFailed: {
			Logger.warn("Location", "Failed to load location file")
			updateWeather()
		}

		JsonAdapter {
			id: adapter
			property string latitude: ""
			property string longitude: ""
			property string name: ""
			property int weatherLastFetch: 0
			property var weather: null
		}
	}

	readonly property string displayCoordinates: {
		if (!coordinatesReady || stableLatitude === "" || stableLongitude === "")
			return ""
		return `${parseFloat(stableLatitude).toFixed(4)}, ${parseFloat(stableLongitude).toFixed(4)}`
	}

	Timer {
		id: updateTimer
		interval: 20000
		running: true
		repeat: true
		onTriggered: updateWeather()
	}

	Timer {
		id: saveTimer
		interval: 1000
		running: false
		onTriggered: locationFileView.writeAdapter()
	}

	function init() {
		Logger.log("Location", "Service started")
	}

	function resetWeather() {
		Logger.log("Location", "Resetting weather data")

		coordinatesReady = false
		stableLatitude = ""
		stableLongitude = ""
		stableName = ""

		adapter.latitude = ""
		adapter.longitude = ""
		adapter.name = ""
		adapter.weatherLastFetch = 0
		adapter.weather = null

		updateWeather()
	}

	function updateWeather() {
		if (isFetchingWeather) {
			Logger.warn("Location", "Weather is already being fetched")
			return
		}

		if (
			adapter.weather === null ||
			adapter.latitude === "" ||
			adapter.longitude === "" ||
			adapter.name !== Settings.data.location.name ||
			Time.timestamp >= adapter.weatherLastFetch + weatherUpdateFrequency
		) {
			getFreshWeather()
		}
	}

	function getFreshWeather() {
		isFetchingWeather = true

		const locationChanged = adapter.name !== Settings.data.location.name
		if (locationChanged) {
			coordinatesReady = false
			Logger.log("Location", "Location changed from", adapter.name, "to", Settings.data.location.name)
		}

		if (adapter.latitude === "" || adapter.longitude === "" || locationChanged) {
			_geocodeLocation(Settings.data.location.name, function (latitude, longitude, city, country) {
				Logger.log("Location", "Geocoded to:", latitude, "/", longitude)

				adapter.name = Settings.data.location.name
				adapter.latitude = latitude.toString()
				adapter.longitude = longitude.toString()
				stableName = `${city}, ${country}`

				_fetchWeather(latitude, longitude)
			}, errorCallback)
		} else {
			_fetchWeather(adapter.latitude, adapter.longitude)
		}
	}

	
		function _geocodeLocation(locationName, callback, errorCallback) {
		Logger.log("Location", "Geocoding:", locationName)
		const geoUrl = "https://geocode.xyz/" + encodeURIComponent(locationName) + "?json=1"
		const xhr = new XMLHttpRequest()

		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				if (xhr.status === 200) {
					try {
						const geoData = JSON.parse(xhr.responseText)

						// Vérification de la présence de 'alt.loc' sous forme de tableau
						if (geoData.alt && Array.isArray(geoData.alt.loc) && geoData.alt.loc.length > 0) {
							const bestMatch = geoData.alt.loc[0] // Prend le 1er résultat
							const latitude = bestMatch.latt
							const longitude = bestMatch.longt
							const city = bestMatch.city || geoData.standard?.city || "Unknown"
							const country = bestMatch.countryname || geoData.standard?.countryname || "Unknown"

							if (latitude && longitude) {
								callback(latitude, longitude, city, country)
							} else {
								errorCallback("Location", "Incomplete geocoding result")
							}
						} else {
							errorCallback("Location", "No valid geocoding results")
						}
					} catch (e) {
						errorCallback("Location", "Failed to parse geocoding response: " + e)
					}
				} else {
					errorCallback("Location", "Geocoding failed with status: " + xhr.status)
				}
			}
		}

		xhr.open("GET", geoUrl)
		xhr.send()
	}

	function _fetchWeather(latitude, longitude) {
		Logger.log("Location", "Fetching weather...")
		const url = `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}` +
			"&current_weather=true&current=relativehumidity_2m,surface_pressure&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto"

		const xhr = new XMLHttpRequest()
		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				if (xhr.status === 200) {
					try {
						const weatherData = JSON.parse(xhr.responseText)

						adapter.weather = weatherData
						adapter.weatherLastFetch = Time.timestamp

						stableLatitude = adapter.latitude = weatherData.latitude.toString()
						stableLongitude = adapter.longitude = weatherData.longitude.toString()
						coordinatesReady = true

						Logger.log("Location", "Weather data fetched and saved")
					} catch (e) {
						errorCallback("Location", "Failed to parse weather data: " + e)
					}
				} else {
					errorCallback("Location", "Weather fetch failed with status: " + xhr.status)
				}
				isFetchingWeather = false
			}
		}
		xhr.open("GET", url)
		xhr.send()
	}

	function errorCallback(module, message) {
		Logger.error(module, message)
		isFetchingWeather = false
	}

	function weatherSymbolFromCode(code) {
		if (code === 0) return "sunny"
		if (code === 1 || code === 2) return "partly_cloudy_day"
		if (code === 3) return "cloud"
		if (code >= 45 && code <= 48) return "foggy"
		if (code >= 51 && code <= 67) return "rainy"
		if (code >= 71 && code <= 77) return "weather_snowy"
		if (code >= 80 && code <= 82) return "rainy"
		if (code >= 95 && code <= 99) return "thunderstorm"
		return "cloud"
	}

	function weatherDescriptionFromCode(code) {
		if (code === 0) return "Clear sky"
		if (code === 1) return "Mainly clear"
		if (code === 2) return "Partly cloudy"
		if (code === 3) return "Overcast"
		if (code === 45 || code === 48) return "Fog"
		if (code >= 51 && code <= 67) return "Drizzle"
		if (code >= 71 && code <= 77) return "Snow"
		if (code >= 80 && code <= 82) return "Rain showers"
		if (code >= 95 && code <= 99) return "Thunderstorm"
		return "Unknown"
	}

	function celsiusToFahrenheit(celsius) {
		return 32 + celsius * 1.8
	}
}
