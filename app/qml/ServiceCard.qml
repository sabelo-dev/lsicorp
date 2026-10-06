import QtQuick
import QtQuick.Layouts
import LsiTools

// One service, as a tappable card that leads to the Services page.
Card {
    id: card

    property var service

    to: "/services"
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop
    Layout.preferredWidth: 1

    ProductMark {
        mark: card.service.mark
    }

    LinkText {
        Layout.fillWidth: true
        text: card.service.name
        to: card.to
        strong: true
        current: true
        padding: 0
        font.pixelSize: Theme.h3
    }

    P {
        text: card.service.tagline
    }

    Item {
        Layout.fillHeight: true
    }

    Text {
        text: "Learn more ›"
        color: Theme.accent
        font.pixelSize: Theme.small
        font.weight: Font.DemiBold
        Accessible.ignored: true
    }
}
