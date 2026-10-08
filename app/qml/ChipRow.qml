import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import LsiTools

// One-of-many choice shown as a row of squared chips: quicker than a
// drop-down, and every option is visible. options: [{ value, text }].
Flow {
    id: root

    property var options: []
    property string value: ""
    property string label: ""

    Layout.fillWidth: true
    spacing: Theme.s2
    Accessible.role: Accessible.Grouping
    Accessible.name: label

    Repeater {
        model: root.options

        T.AbstractButton {
            id: chip

            required property var modelData
            readonly property bool selected: root.value === modelData.value

            implicitWidth: text.implicitWidth + 2 * Theme.s3
            implicitHeight: Theme.controlSmall
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.RadioButton
            Accessible.name: modelData.text
            Accessible.checked: selected

            onClicked: root.value = modelData.value
            onActiveFocusChanged: if (activeFocus) Theme.reveal(chip)
            Keys.onReturnPressed: click()
            Keys.onEnterPressed: click()

            background: Rectangle {
                radius: Theme.controlRadius
                color: chip.selected ? Theme.primary : chip.hovered || chip.down ? Theme.surfaceAlt : Theme.surface
                border.width: chip.visualFocus ? 2 : 1
                border.color: chip.visualFocus ? Theme.focus : chip.selected ? Theme.primary : Theme.controlBorder

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fast
                    }
                }
            }

            contentItem: Text {
                id: text
                text: chip.modelData.text
                color: chip.selected ? Theme.primaryInk : Theme.ink
                font.pixelSize: Theme.small
                font.weight: chip.selected ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
