import QtQuick
import QtQuick.Templates as T
import LsiTools

// A search input that filters as you type: a magnifier, the text, and a
// one-press clear button once there is something to clear. Escape clears the
// text first; pressed again on an empty field, it lets go of the keyboard.
Input {
    id: control

    /// What the clear button is called, for example "Clear search".
    property string clearLabel: "Clear search"

    function clear() {
        text = "";
        forceActiveFocus();
    }

    leftPadding: Theme.s4 + 18 + Theme.s2
    rightPadding: clearButton.visible ? clearButton.width + Theme.s1 : Theme.s4
    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

    Keys.onEscapePressed: event => {
        if (text !== "")
            text = "";
        else
            focus = false;
        event.accepted = true;
    }

    Icon {
        x: Theme.s4
        anchors.verticalCenter: parent.verticalCenter
        name: "search"
        size: 18
        color: Theme.muted
    }

    T.AbstractButton {
        id: clearButton

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.touch
        height: Theme.touch
        visible: control.text !== ""
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: control.clearLabel
        onClicked: control.clear()
        Keys.onReturnPressed: click()
        Keys.onEnterPressed: click()

        background: Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: Theme.controlRadius - 4
            color: clearButton.hovered || clearButton.down ? Theme.surfaceAlt : "transparent"
            border.width: clearButton.visualFocus ? 3 : 0
            border.color: Theme.focus
        }

        contentItem: Item {
            Icon {
                anchors.centerIn: parent
                name: "close"
                size: 16
                color: Theme.muted
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}
