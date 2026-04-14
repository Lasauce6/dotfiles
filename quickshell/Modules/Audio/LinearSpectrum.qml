import QtQuick
import qs.Commons

Item {
	id: root
	property color fillColor: Color.mPrimary
	property color strokeColor: Color.mOnSurface
	property int strokeWidth: 0
	property var values: []

	// Pre compute horizontal mirroring
	readonly property int valuesCount: values.length
	readonly property real barSlotWidth: valuesCount > 0 ? width / valuesCount : 0

	Repeater {
		model: root.valuesCount

		Rectangle {
			property real amp: root.values[index]

			color: root.fillColor
			border.color: root.strokeColor
			border.width: root.strokeWidth
			antialiasing: true

			width: root.barSlotWidth * 0.5 // Creates a small gap between bars
			height: Math.max(1, root.height * amp)
			x: index * root.barSlotWidth
			y: root.height - height
		}
	}
}
