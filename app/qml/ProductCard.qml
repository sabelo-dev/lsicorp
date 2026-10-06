import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// The whole card opens the product; the name is also a link for keyboard users.
Card {
    id: card

    property var product

    to: "/work/" + product.slug
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop
    // Equal-width columns regardless of content.
    Layout.preferredWidth: 1

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.s3

        ProductMark {
            Layout.alignment: Qt.AlignTop
            mark: card.product.mark
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            LinkText {
                Layout.fillWidth: true
                text: card.product.public_name
                to: card.to
                strong: true
                current: true
                padding: 0
                bottomPadding: 2
                font.pixelSize: Theme.h3
            }

            P {
                small: true
                muted: true
                text: card.product.category
            }
        }
    }

    P {
        text: card.product.summary
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.fillWidth: true

        StatusBadge {
            tone: card.product.status
            label: Rules.PRODUCT_STATUSES[card.product.status]
            prefix: "Status"
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: "View ›"
            color: Theme.accent
            font.pixelSize: Theme.small
            font.weight: Font.DemiBold
            Accessible.ignored: true
        }
    }
}
