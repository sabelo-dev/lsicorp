import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools

// Single-line text input, sized for touch.
TextField {
    id: control

    Layout.fillWidth: true
    implicitHeight: Theme.touch
    leftPadding: Theme.s4
    rightPadding: Theme.s4
    font.pixelSize: Theme.body
    color: Theme.ink
    placeholderTextColor: Theme.muted
    selectByMouse: true
    onActiveFocusChanged: if (activeFocus) Theme.reveal(control)

    background: Rectangle {
        radius: Theme.controlRadius
        color: control.readOnly ? Theme.surfaceAlt : Theme.surface
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Theme.focus : Theme.muted
    }
}
