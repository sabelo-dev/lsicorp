import QtQuick
import QtQuick.Layouts
import LsiTools

// A caution that must not be missed, such as a risk statement or a withdrawal.
Rectangle {
    id: notice

    property string title: ""
    property string body: ""
    property string tone: "in-development"

    Layout.fillWidth: true
    Layout.maximumWidth: Theme.measure
    implicitHeight: column.implicitHeight + 2 * Theme.s4
    color: Theme.tone(tone)[0]
    radius: Theme.radius
    Accessible.role: Accessible.Note
    Accessible.name: title + ". " + body

    // Clipped by hand to the rounded corner: a 3-pixel rule down the left edge.
    Rectangle {
        x: 0
        y: Theme.radius
        width: 3
        height: parent.height - 2 * Theme.radius
        color: Theme.tone(notice.tone)[1]
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.s4
        anchors.leftMargin: Theme.s5
        spacing: Theme.s2

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: notice.title
            wrapMode: Text.Wrap
            color: Theme.tone(notice.tone)[1]
            font.pixelSize: Theme.body
            font.weight: Font.Bold
        }

        Text {
            Layout.fillWidth: true
            text: notice.body
            wrapMode: Text.Wrap
            color: Theme.tone(notice.tone)[1]
            font.pixelSize: Theme.body
            lineHeight: 1.3
        }
    }
}
