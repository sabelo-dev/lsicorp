import QtQuick
import QtQuick.Layouts
import LsiTools

// Placeholder shapes in the layout of a real page, shown while content loads,
// so the page does not jump when it arrives.
PageScroll {
    id: page

    component Bone: Rectangle {
        Layout.fillWidth: true
        radius: Theme.controlRadius
        color: Theme.surfaceAlt

        SequentialAnimation on opacity {
            running: Theme.motion
            loops: Animation.Infinite

            NumberAnimation {
                from: 1
                to: 0.45
                duration: 800
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                from: 0.45
                to: 1
                duration: 800
                easing.type: Easing.InOutSine
            }
        }
    }

    Text {
        text: "Loading…"
        color: Theme.muted
        font.pixelSize: Theme.small
        Accessible.role: Accessible.AlertMessage
        Accessible.name: "Loading"
    }

    Bone {
        Layout.maximumWidth: 420
        implicitHeight: 44
    }

    Bone {
        Layout.maximumWidth: 640
        implicitHeight: 22
    }

    Bone {
        Layout.maximumWidth: 520
        implicitHeight: 22
    }

    CardGrid {
        Layout.topMargin: Theme.s5

        Repeater {
            model: 3

            Bone {
                Layout.preferredWidth: 1
                implicitHeight: 200
                radius: Theme.radius
            }
        }
    }
}
