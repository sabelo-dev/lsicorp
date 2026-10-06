import QtQuick
import QtQuick.Layouts
import LsiTools

// Label and value pairs. Stacks on narrow screens.
// model: [{ label, value, mono }]
ColumnLayout {
    id: root

    property var model: []
    property int labelWidth: 170

    Layout.fillWidth: true
    Layout.maximumWidth: Theme.measure
    spacing: Theme.s2

    Repeater {
        model: root.model

        GridLayout {
            id: row

            required property var modelData

            Layout.fillWidth: true
            columns: Theme.narrow ? 1 : 2
            columnSpacing: Theme.s4
            rowSpacing: 0
            Accessible.role: Accessible.StaticText
            Accessible.name: row.modelData.label + ": " + row.modelData.value

            Text {
                Layout.preferredWidth: Theme.narrow ? -1 : root.labelWidth
                Layout.fillWidth: Theme.narrow
                Layout.alignment: Qt.AlignTop
                text: row.modelData.label
                color: Theme.muted
                font.pixelSize: Theme.small
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: row.modelData.value
                color: Theme.ink
                font.pixelSize: Theme.small
                font.family: row.modelData.mono ? "monospace" : Qt.application.font.family
                wrapMode: row.modelData.mono ? Text.WrapAnywhere : Text.Wrap
                lineHeight: 1.25
            }
        }
    }
}
