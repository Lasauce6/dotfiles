
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons

Singleton {
	id: root

	// PIPEWIRE NODES

	readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
		if (!node.isStream) {
			if (node.isSink) acc.sinks.push(node)
			else if (node.audio) acc.sources.push(node)
		}
		return acc
	}, { "sources": [], "sinks": [] })

	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property PwNode source: Pipewire.defaultAudioSource
	readonly property list<PwNode> sinks: nodes.sinks
	readonly property list<PwNode> sources: nodes.sources

	// VOLUME STATE

	property real volume: sink?.audio?.volume ?? 0
	property bool muted: sink?.audio?.muted ?? false
	property real inputVolume: source?.audio?.volume ?? 0
	property bool inputMuted: source?.audio?.muted ?? false

	readonly property real stepVolume: Settings.data.audio.volumeStep / 100.0

	// PIPEWIRE CHECK

	function pwHasVolumeControl(node) {
		return node?.audio &&
		node?.audio.volume !== null &&
		node?.audio.volumes?.length > 0
	}

	readonly property bool pipewireVolumeOK: pwHasVolumeControl(sink)

	// TRACKER

	PwObjectTracker {
		objects: [...root.sinks, ...root.sources]
	}

	// PIPEWIRE CONNECTIONS

	Connections {
		target: sink?.audio ?? null
		ignoreUnknownSignals: true

		function onVolumeChanged() {
			var v = sink?.audio?.volume
			if (isNaN(v)) v = 0
			root.volume = v
		}

		function onMutedChanged() {
			root.muted = sink?.audio?.muted ?? false
		}
	}

	Connections {
		target: source?.audio ?? null
		ignoreUnknownSignals: true

		function onVolumeChanged() {
			var v = source?.audio?.volume
			if (isNaN(v)) v = 0
			root.inputVolume = v
		}

		function onMutedChanged() {
			root.inputMuted = source?.audio?.muted ?? false
		}
	}

	// PAMIXER PROCESS

	Process {
		id: pamixerProc
		running: false
		command: []

		stdout: StdioCollector {
			id: pamixerOut
			onStreamFinished: function(text) {
				let safe = text ?? ""
				if (root._callback) {
					root._callback(safe.trim())
				}
				root._callback = null
			}
		}
	}

	property var _callback: null

	function pamixerExec(args, callback = null) {
		pamixerProc.command = ["pamixer"].concat(args)
		root._callback = callback
		pamixerProc.running = true
	}

	function pamixerGetVolume() {
		pamixerExec(["--get-volume"], function(out) {
			var vol = parseInt(out)
			if (!isNaN(vol)) root.volume = vol / 100
		})
	}

	function pamixerGetMute() {
		pamixerExec(["--get-mute"], function(out) {
			root.muted = (out === "true")
		})
	}

	// SYNC TIMER

	Timer {
		interval: 350
		repeat: true
		running: true
		onTriggered: {
			if (!root.pipewireVolumeOK) {
				pamixerGetVolume()
				pamixerGetMute()
			}
		}
	}

	// PUBLIC API

	function increaseVolume() { setVolume(volume + stepVolume) }
	function decreaseVolume() { setVolume(volume - stepVolume) }

	function setVolume(newVolume) {
		const vol = Math.max(0, Math.min(1, newVolume))

		if (pipewireVolumeOK) {
			sink.audio.muted = false
			sink.audio.volume = vol
		} else {
			pamixerExec(["--set-volume", Math.round(vol * 100)])
		}
	}

	function setMuted(m) {
		if (pipewireVolumeOK) {
			sink.audio.muted = m
		} else {
			pamixerExec([m ? "--mute" : "--unmute"])
		}
	}

	// Input (PipeWire only)

	function setInputVolume(newVolume) {
		const vol = Math.max(0, Math.min(1, newVolume))
		if (source?.ready && source?.audio) {
			source.audio.muted = false
			source.audio.volume = vol
		}
	}

	function setInputMuted(m) {
		if (source?.ready && source?.audio) {
			source.audio.muted = m
		}
	}

	// Preferred devices

	function setAudioSink(newSink) {
		Pipewire.preferredDefaultAudioSink = newSink
	}

	function setAudioSource(newSource) {
		Pipewire.preferredDefaultAudioSource = newSource
	}
}

