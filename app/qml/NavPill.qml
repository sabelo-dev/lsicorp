import QtQuick
import QtQuick.Templates as T
import LsiTools

// One destination in the main navigation. `wide` makes it a full-width row
// for the menu on small screens.
T.AbstractButton {
    id: control

    property string to: ""
    property bool current: false
    property bool wide: false

    implicitWidth: wide ? 200 : label.implicitWidth + 2 * Theme.s3
    implicitHeight: wide ? 52 : 36
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.Link
    Accessible.name: text + (current ? ", current section" : "")

    onClicked: if (to) Nav.go(to)
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    background: Rectangle {
        radius: Theme.controlRadius
        color: control.wide && control.current ? Theme.primarySoft : control.hovered || control.down ? Theme.surfaceAlt : "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.focus

        Behavior on color {
            ColorAnimation {
                duration: Theme.fast
            }
        }

        // The current section is marked by a bar, not by colour alone.
        Rectangle {
            visible: control.current
            x: control.wide ? 0 : (parent.width - width) / 2
            y: control.wide ? (parent.height - height) / 2 : parent.height - height
            width: control.wide ? 3 : parent.width - 2 * Theme.s3
            height: control.wide ? 22 : 2
            radius: 1
            color: Theme.dark ? Theme.primary : Theme.navy
        }
    }

    contentItem: Text {
        id: label
        leftPadding: control.wide ? Theme.s4 : 0
        text: control.text
        color: control.current ? (Theme.dark ? Theme.primary : Theme.navy) : control.wide || control.hovered ? Theme.ink : Theme.muted
        font.pixelSize: control.wide ? 17 : Theme.label
        font.weight: control.current ? Font.DemiBold : Font.Normal
        horizontalAlignment: control.wide ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
