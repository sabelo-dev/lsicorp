import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools

// Drop-down for choosing one of many options, with rows tall enough to tap.
// model: [{ value, text }].
ComboBox {
    id: control

    Layout.fillWidth: true
    implicitHeight: Theme.control
    leftPadding: Theme.s3
    font.pixelSize: Theme.body
    textRole: "text"
    valueRole: "value"
    onActiveFocusChanged: if (activeFocus) Theme.reveal(control)

    background: Rectangle {
        radius: Theme.controlRadius
        color: control.enabled ? Theme.surface : Theme.surfaceAlt
        border.width: control.visualFocus || control.popup.visible ? 2 : 1
        border.color: control.visualFocus || control.popup.visible ? Theme.focus : Theme.controlBorder
    }

    contentItem: Text {
        text: control.displayText
        color: Theme.ink
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: control.width - width - Theme.s3
        y: (control.height - height) / 2
        text: "▾"
        color: Theme.muted
        font.pixelSize: 18
    }

    delegate: ItemDelegate {
        id: option

        required property var modelData
        required property int index

        width: control.width
        height: Theme.control
        highlighted: control.highlightedIndex === index

        contentItem: Text {
            text: option.modelData.text
            color: Theme.ink
            font.pixelSize: Theme.body
            font.weight: control.currentIndex === option.index ? Font.DemiBold : Font.Normal
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: option.highlighted || option.hovered ? Theme.primarySoft : Theme.surface
        }
    }

    popup.background: Rectangle {
        radius: Theme.controlRadius
        color: Theme.surface
        border.color: Theme.border
    }
}
