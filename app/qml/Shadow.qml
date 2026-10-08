import QtQuick
import LsiTools

// A soft drop shadow built from a few stacked, slightly larger plates. Much
// cheaper than a blur, and it reads as one. Declare it inside the item that
// casts the shadow; it sits behind that item's own surface. The interface is
// flat, so only something that floats above the page (a panel, a menu) uses it.
Item {
    id: root

    property real radius: Theme.radius
    /// 0 = flat, 1 = resting, 2 or more = lifted.
    property real elevation: 1

    z: -1
    anchors.fill: parent

    Behavior on elevation {
        NumberAnimation {
            duration: Theme.fast
            easing.type: Easing.OutCubic
        }
    }

    // More, fainter layers with small steps between them read as a smooth falloff.
    Repeater {
        model: 8

        Rectangle {
            required property int index
            readonly property real spread: (index + 1) * 0.9 * root.elevation

            x: -spread
            y: -spread + (index + 1) * 0.75 * root.elevation
            width: root.width + 2 * spread
            height: root.height + 2 * spread
            radius: root.radius + spread
            color: Theme.shadowLayer
            opacity: root.elevation > 0 ? Theme.shadowOpacity : 0
        }
    }
}
