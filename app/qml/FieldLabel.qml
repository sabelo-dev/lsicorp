import QtQuick
import QtQuick.Layouts
import LsiTools

// A visible label stacked above the control placed inside it.
ColumnLayout {
    property alias text: label.text
    property string hint: ""

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
        text: parent.hint
        color: Theme.muted
        font.pixelSize: Theme.small
        wrapMode: Text.Wrap
    }
}
