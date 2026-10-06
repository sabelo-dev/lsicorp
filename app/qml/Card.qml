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

    Shadow {
        radius: card.radius
        elevation: card.lifted ? 2.2 : 1
    }

    transform: Translate {
        y: card.lifted ? -3 : 0

        Behavior on y {
            NumberAnimation {
                duration: Theme.fast
                easing.type: Easing.OutCubic
            }
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.fast
        }
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
