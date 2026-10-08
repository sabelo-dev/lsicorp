import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools

// Single-line text input, sized for touch.
TextField {
    id: control

    /// Set when the value was refused; the reason is shown by the FieldLabel around it.
    property bool invalid: false

    Layout.fillWidth: true
    implicitHeight: Theme.control
    leftPadding: Theme.s3
    rightPadding: Theme.s3
    font.pixelSize: Theme.body
    color: Theme.ink
    placeholderTextColor: Theme.muted
    selectByMouse: true
    onActiveFocusChanged: if (activeFocus) Theme.reveal(control)

    background: Rectangle {
        radius: Theme.controlRadius
        color: control.readOnly ? Theme.surfaceAlt : Theme.surface
        border.width: control.activeFocus || control.invalid ? 2 : 1
        border.color: control.activeFocus ? Theme.focus : control.invalid ? Theme.danger : Theme.controlBorder
    }
}
