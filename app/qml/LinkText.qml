import QtQuick
import QtQuick.Templates as T
import LsiTools

// A text link that can be reached and activated from the keyboard.
// Set `to` for a page in the app, or handle clicked() for anything else.
T.AbstractButton {
    id: control

    property string to: ""
    property bool strong: false
    property bool current: false

    implicitWidth: label.implicitWidth + leftPadding + rightPadding
    implicitHeight: label.implicitHeight + topPadding + bottomPadding
    // Padding widens the area a finger can hit without moving the text.
    padding: 6
    focusPolicy: Qt.StrongFocus
    font.pixelSize: Theme.body
    Accessible.role: Accessible.Link
    Accessible.name: text

    onClicked: if (to) Nav.go(to)
    onActiveFocusChanged: if (activeFocus) Theme.reveal(control)
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    contentItem: Text {
        id: label
        text: control.text
        color: control.hovered || control.down ? Theme.accentHover : Theme.accent
        font.pixelSize: control.font.pixelSize
        font.underline: !control.current
        font.weight: control.strong || control.current ? Font.DemiBold : Font.Normal
        wrapMode: Text.Wrap
    }

    background: Rectangle {
        color: control.down ? Theme.primarySoft : "transparent"
        radius: 6
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.focus
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
