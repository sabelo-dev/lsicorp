import QtQuick
import QtQuick.Layouts
import LsiTools

// Paragraph of plain text, kept to a readable line length.
Text {
    property bool muted: false
    property bool lede: false
    property bool small: false

    Layout.fillWidth: true
    Layout.maximumWidth: Theme.measure
    wrapMode: Text.Wrap
    textFormat: Text.PlainText
    color: muted || lede ? Theme.muted : Theme.ink
    font.pixelSize: lede ? (Theme.narrow ? 18 : Theme.h3) : small ? Theme.small : Theme.body
    lineHeight: 1.45
    Accessible.role: Accessible.StaticText
    Accessible.name: text
}
