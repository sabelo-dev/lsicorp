import QtQuick
import QtQuick.Layouts
import LsiTools

// A visible label stacked above the control placed inside it. A problem with
// what was entered is shown between the label and the control, in words.
ColumnLayout {
    id: root

    property alias text: label.text
    property string hint: ""
    property string error: ""

    Layout.fillWidth: true
    spacing: Theme.s1

    Text {
        id: label
        Layout.fillWidth: true
        color: Theme.ink
        font.pixelSize: Theme.small
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
    }

    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.hint
        color: Theme.muted
        font.pixelSize: Theme.small
        wrapMode: Text.Wrap
    }

    Text {
        Layout.fillWidth: true
        visible: root.error !== ""
        text: "Problem: " + root.error
        color: Theme.danger
        font.pixelSize: Theme.small
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
        Accessible.role: Accessible.AlertMessage
        Accessible.name: text
    }
}
