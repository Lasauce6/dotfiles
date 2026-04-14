import QtQuick
import qs.Commons

Item {
	id: root
	property color fillColor: Color.mPrimary
	property color strokeColor: Color.mOnSurface
	property int strokeWidth: 0
	property var values: []

	// Pre-compute mirroring
	readonly property int valuesCount: values.length
	readonly property real barSlotWidth: valuesCount > 0 ? width / valuesCount : 0

	readonly property real centerY: height / 2

	Repeater {
		model: root.valuesCount

		Rectangle {
			property real amp: root.values[index]

			property real barHeight: root.height * amp

			color: root.fillColor
			border.color: root.strokeColor
			border.width: root.strokeWidth
			antialiasing: true

			width: root.barSlotWidth * 0.8 // Creates a small gap between bars
			height: Math.max(1, barHeight)
			x: index * root.barSlotWidth
			y: root.centerY - (barHeight / 2)
		}
	}
}
