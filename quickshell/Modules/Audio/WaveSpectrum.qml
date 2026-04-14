import QtQuick
import qs.Commons

Item {
	id: root
	property color fillColor: Color.mPrimary
	property color strokeColor: Color.mOnSurface
	property int strokeWidth: 0
	property var values: []

	// Redraw when necessary
	onWidthChanged: canvas.requestPaint()
	onHeightChanged: canvas.requestPaint()
	onValuesChanged: canvas.requestPaint()
	onFillColorChanged: canvas.requestPaint()
	onStrokeColorChanged: canvas.requestPaint()

	Canvas {
		id: canvas
		anchors.fill: parent
		antialiasing: true

		onPaint: {
			var ctx = getContext("2d")
			ctx.reset()

			if (values.length < 2) {
				return
			}

			ctx.fillStyle = root.fillColor
			ctx.strokeStyle = root.strokeColor
			ctx.lineWidth = root.strokeWidth

			const count = values.length
			const stepX = width / (count - 1)
			const centerY = height / 2
			const amplitude = height / 2

			ctx.beginPath()
			// Draw top half of waveform (basses to left, aigus to right)
			var yOffset = Math.max(1, values[0] * amplitude)
			ctx.moveTo(0, centerY - yOffset)

			for (var i = 1; i < count; i++) {
				const x = i * stepX
				yOffset = Math.max(1, values[i] * amplitude)
				const y = centerY - yOffset
				ctx.lineTo(x, y)
			}

			// Draw bottom half of waveform (from right to left, mirrored vertically)
			for (var i = count - 1; i >= 0; i--) {
				const x = i * stepX
				yOffset = Math.max(1, values[i] * amplitude)
				const y = centerY + yOffset // Mirrored across the center
				ctx.lineTo(x, y)
			}

			ctx.closePath()

			// --- Render the path ---
			if (root.fillColor.a > 0) {
				ctx.fill()
			}
			if (root.strokeWidth > 0) {
				ctx.stroke()
			}
		}
	}
}
