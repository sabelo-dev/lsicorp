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

    implicitWidth: wide ? 200 : label.implicitWidth + 2 * Theme.s4
    implicitHeight: wide ? 56 : 44
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.Link
    Accessible.name: text + (current ? ", current section" : "")

    onClicked: if (to) Nav.go(to)
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    background: Rectangle {
        radius: control.wide ? Theme.controlRadius : height / 2
        color: control.current ? Theme.primarySoft : control.hovered || control.down ? Theme.surfaceAlt : "transparent"
        border.width: control.visualFocus ? 3 : 0
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
            y: control.wide ? (parent.height - height) / 2 : parent.height - height - 5
            width: control.wide ? 4 : 18
            height: control.wide ? 24 : 3
            radius: 2
            color: Theme.dark ? Theme.primary : Theme.navy
        }
    }

    contentItem: Text {
        id: label
        leftPadding: control.wide ? Theme.s4 : 0
        text: control.text
        color: control.current ? (Theme.dark ? Theme.primary : Theme.navy) : Theme.ink
        font.pixelSize: control.wide ? 18 : Theme.body
        font.weight: control.current ? Font.DemiBold : Font.Normal
        horizontalAlignment: control.wide ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
