import QtQuick
import QtQuick.Layouts
import LsiTools

// Says plainly that there is nothing here, in place of a control that would not work.
Rectangle {
    property alias text: label.text

    Layout.fillWidth: true
    Layout.maximumWidth: Theme.measure
    implicitHeight: label.implicitHeight + 2 * Theme.s4
    color: Theme.surfaceAlt
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    Text {
        id: label
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.s4
        wrapMode: Text.Wrap
        color: Theme.muted
        font.pixelSize: Theme.body
        lineHeight: 1.3
        Accessible.role: Accessible.StaticText
        Accessible.name: text
    }
}
