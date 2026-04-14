import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.SettingsPanel
import qs.Services 1.0 as Services
import qs.Widgets

Item {
	id: root

	property ShellScreen screen
	property real scaling: 1.0
	property string barSection: ""
	property int sectionWidgetIndex: 0
	property int sectionWidgetsCount: 0

	property bool firstVolumeReceived: false
	property int wheelAccumulator: 0

	implicitWidth: pill.width
	implicitHeight: pill.height

	function getIcon() {
		if (Services.AudioService.muted) {
			return "volume_off"
		}
		return Services.AudioService.volume <= Number.EPSILON ? "volume_off" :
		(Services.AudioService.volume < 0.33 ? "volume_down" : "volume_up")
	}

	Connections {
		target: Services.AudioService.sink?.audio ? Services.AudioService.sink.audio : null
		function onVolumeChanged() {
			if (!firstVolumeReceived) {
				firstVolumeReceived = true
			} else {
				pill.show()
				externalHideTimer.restart()
			}
		}
	}

	Timer {
		id: externalHideTimer
		running: false
		interval: 1500
		onTriggered: {
			pill.hide()
		}
	}

	NPill {
		id: pill

		rightOpen: BarWidgetRegistry.getNPillDirection(root)
		icon: getIcon()
		iconCircleColor: Color.mPrimary
		collapsedIconColor: Color.mOnSurface
		autoHide: false
		text: Math.floor(Services.AudioService.volume * 100) + "%"
		tooltipText: "Volume: " + Math.round(Services.AudioService.volume * 100) +
		"%\nLeft click for advanced settings.\nScroll up/down to change volume."

		onWheel: function(delta) {
			wheelAccumulator += delta
			if (wheelAccumulator >= 120) {
				wheelAccumulator = 0
				Services.AudioService.increaseVolume()
			} else if (wheelAccumulator <= -120) {
				wheelAccumulator = 0
				Services.AudioService.decreaseVolume()
			}
		}

		onClicked: {
			var settingsPanel = PanelService.getPanel("settingsPanel")
			settingsPanel.requestedTab = SettingsPanel.Tab.AudioService
			settingsPanel.open(screen)
		}

		onRightClicked: {
			pwvucontrolProcess.running = true
		}
	} // fin NPill

	Process {
		id: pwvucontrolProcess
		command: ["pwvucontrol"]
		running: false
	}
}
