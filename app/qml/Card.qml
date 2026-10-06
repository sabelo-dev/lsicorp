import QtQuick
import QtQuick.Layouts
import LsiTools

// Raised surface that stacks its children vertically. Give it `to` and the
// whole card becomes a target for a tap or click, which is easier to hit than
// a line of link text.
Rectangle {
    id: card

    default property alias content: inner.data
    property int padding: Theme.narrow ? Theme.s4 : Theme.s5
    property string to: ""
    readonly property bool interactive: to !== ""
    readonly property bool lifted: interactive && (hover.hovered || tap.pressed)

    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + 2 * padding
    color: Theme.surface
    border.color: lifted ? Theme.primary : Theme.border
    border.width: 1
    radius: Theme.radius

    // Soft shadow: a blurred-looking offset plate behind the card.
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: card.lifted ? 8 : 3
        anchors.bottomMargin: card.lifted ? -8 : -3
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        radius: card.radius
        color: Theme.shadow
        opacity: card.lifted ? 1 : 0.6
    }

    HoverHandler {
        id: hover
        enabled: card.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        enabled: card.interactive
        onTapped: Nav.go(card.to)
    }

    ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.margins: card.padding
        spacing: Theme.s3
    }
}
