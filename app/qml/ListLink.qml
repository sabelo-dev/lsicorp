import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import LsiTools

// A full-width row that links somewhere: title, optional description and a
// chevron. The whole row is the target, so it is easy to hit with a finger.
T.AbstractButton {
    id: control

    property string to: ""
    property string description: ""
    property bool current: false

    Layout.fillWidth: true
    Layout.maximumWidth: Theme.measure
    implicitHeight: Math.max(Theme.control + 8, column.implicitHeight + 2 * Theme.s3)
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.Link
    Accessible.name: text + (current ? ", current page" : "") + (description ? ". " + description : "")

    onClicked: if (to) Nav.go(to)
    onActiveFocusChanged: if (activeFocus) Theme.reveal(control)
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    background: Rectangle {
        radius: Theme.controlRadius
        color: control.current ? Theme.primarySoft : control.hovered || control.down ? Theme.surfaceAlt : Theme.surface
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? Theme.focus : control.hovered ? Theme.primary : Theme.border
    }

    contentItem: Item {
        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.s4
            anchors.rightMargin: Theme.s3
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: control.text
                color: Theme.ink
                font.pixelSize: Theme.body
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                visible: control.description !== ""
                text: control.description
                color: Theme.muted
                font.pixelSize: Theme.small
                lineHeight: 1.35
                wrapMode: Text.Wrap
            }
        }

        Text {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: Theme.s4
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: Theme.muted
            font.pixelSize: 20
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
