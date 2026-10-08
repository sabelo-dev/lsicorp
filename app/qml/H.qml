import QtQuick
import QtQuick.Layouts
import LsiTools

// Heading. `level` 1 to 4 sets the size and is announced to assistive technology.
// A level 2 heading carries a short gold rule, echoing the logo.
Text {
    id: heading

    property int level: 2
    property bool bar: level === 2

    Layout.fillWidth: true
    Layout.topMargin: level === 1 ? 0 : level === 2 ? Theme.s6 : Theme.s3
    topPadding: bar ? 12 : 0
    wrapMode: Text.Wrap
    color: Theme.ink
    font.pixelSize: level === 1 ? (Theme.narrow ? 30 : Theme.h1) : level === 2 ? (Theme.narrow ? 22 : Theme.h2) : level === 3 ? Theme.h3 : Theme.body
    font.weight: level === 1 ? Font.Bold : Font.DemiBold
    font.letterSpacing: level === 1 ? -1 : level === 2 ? -0.4 : -0.1
    lineHeight: 1.15
    Accessible.role: Accessible.Heading
    Accessible.name: text

    Rectangle {
        visible: heading.bar
        width: 24
        height: 2
        color: Theme.gold
    }
}
