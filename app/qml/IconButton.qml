import QtQuick
import QtQuick.Templates as T
import LsiTools

// A square, touch-sized button that shows only an icon. `label` is what
// assistive technology announces and what the tooltip shows.
T.AbstractButton {
    id: control

    property string glyph: "search"
    property string label: ""

    implicitWidth: Theme.control
    implicitHeight: Theme.control
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    background: Rectangle {
        radius: Theme.controlRadius
        color: control.hovered || control.down ? Theme.surfaceAlt : "transparent"
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? Theme.focus : Theme.border

        Behavior on color {
            ColorAnimation {
                duration: Theme.fast
            }
        }
    }

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            name: control.glyph
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
