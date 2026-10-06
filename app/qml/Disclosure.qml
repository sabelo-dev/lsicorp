import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import LsiTools

// A question that opens to show its answer. Used for FAQs.
ColumnLayout {
    id: root

    property string title: ""
    property string body: ""
    property string note: ""
    property bool open: false

    Layout.fillWidth: true
    Layout.maximumWidth: Theme.measure
    spacing: 0

    T.AbstractButton {
        id: header

        Layout.fillWidth: true
        implicitHeight: Math.max(Theme.touch + 8, question.implicitHeight + 2 * Theme.s3)
        focusPolicy: Qt.StrongFocus
        Accessible.role: Accessible.Button
        Accessible.name: root.title + (root.open ? ", expanded" : ", collapsed")

        onClicked: root.open = !root.open
        onActiveFocusChanged: if (activeFocus) Theme.reveal(header)
        Keys.onReturnPressed: click()
        Keys.onEnterPressed: click()

        background: Rectangle {
            radius: Theme.controlRadius
            color: header.hovered || header.down ? Theme.surfaceAlt : Theme.surface
            border.width: header.visualFocus ? 3 : 1
            border.color: header.visualFocus ? Theme.focus : Theme.border
        }

        contentItem: Item {
            Text {
                id: question
                anchors.left: parent.left
                anchors.right: sign.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Theme.s4
                anchors.rightMargin: Theme.s3
                text: root.title
                color: Theme.ink
                font.pixelSize: Theme.body
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            Text {
                id: sign
                anchors.right: parent.right
                anchors.rightMargin: Theme.s4
                anchors.verticalCenter: parent.verticalCenter
                text: root.open ? "−" : "+"
                color: Theme.accent
                font.pixelSize: 24
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: Theme.s4
        visible: root.open
        spacing: Theme.s2

        P {
            text: root.body
        }

        P {
            visible: root.note !== ""
            small: true
            muted: true
            text: root.note
        }
    }
}
