import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// The whole card opens the product; the name is also a link for keyboard users.
// It says what the product is, its status, and how it can be used today.
Card {
    id: card

    property var product
    /// "Web app", "Windows download": only from releases that are published.
    readonly property var access: Rules.accessFor(product, Store.releases)

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

    P {
        visible: card.access.length > 0
        small: true
        muted: true
        text: "Available as: " + card.access.join(", ")
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
            text: "View project ›"
            color: Theme.muted
            font.pixelSize: Theme.small
            font.weight: Font.DemiBold
            Accessible.ignored: true
        }
    }
}
