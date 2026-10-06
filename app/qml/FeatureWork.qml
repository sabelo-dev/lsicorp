import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// The lead portfolio item, given room: what it is on one side, a brand panel
// on the other, and the quickest way to use it if it is live.
Card {
    id: card

    property var product
    readonly property var release: Rules.availableReleases(Store.releasesFor(product.slug), product.slug, "")[0] || null
    readonly property bool live: release !== null && Store.linkAllowed(release.destination_url)

    padding: 0

    // Positioned by hand rather than with a grid: text takes three fifths on a
    // wide screen and the brand panel the rest; on a phone the text is full width.
    Item {
        id: layout

        readonly property int pad: Theme.narrow ? Theme.s5 : Theme.s6
        readonly property real split: Theme.narrow ? 1 : 0.6

        Layout.fillWidth: true
        implicitHeight: Math.max(textColumn.implicitHeight + 2 * pad, Theme.narrow ? 0 : 300)

        ColumnLayout {
            id: textColumn
            x: layout.pad
            y: layout.pad
            width: layout.width * layout.split - 2 * layout.pad
            spacing: Theme.s3

            Text {
                text: "Featured work"
                color: Theme.dark ? Theme.gold : Theme.navy
                font.pixelSize: Theme.small
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
            }

            H {
                bar: false
                Layout.topMargin: 0
                text: card.product.public_name
            }

            P {
                lede: true
                text: card.product.tagline
            }

            P {
                text: card.product.summary
            }

            StatusBadge {
                tone: card.product.status
                label: Rules.PRODUCT_STATUSES[card.product.status]
                prefix: "Status"
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.s2
                spacing: Theme.s3

                AppButton {
                    visible: card.live
                    text: card.live ? Rules.actionLabel(card.release, card.product.public_name) : ""
                    onClicked: Nav.follow(card.release.destination_url)
                }

                AppButton {
                    text: "View the project"
                    to: "/work/" + card.product.slug
                    secondary: card.live
                }
            }

            P {
                visible: card.live
                small: true
                muted: true
                text: card.live ? "Leaves this website and opens " + Rules.hostOf(card.release.destination_url) + "." : ""
            }
        }

        // Brand panel: decorative.
        Rectangle {
            x: layout.width * layout.split
            width: layout.width - x
            height: layout.height
            visible: !Theme.narrow
            clip: true
            topRightRadius: Theme.radius
            bottomRightRadius: Theme.radius
            Accessible.ignored: true

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Theme.heroBottom
                }

                GradientStop {
                    position: 1
                    color: Theme.heroTop
                }
            }

            Rectangle {
                x: parent.width * 0.55
                y: -60
                width: 220
                height: 220
                radius: 110
                color: Theme.gold
                opacity: 0.2
            }

            Rectangle {
                x: -50
                y: parent.height - 110
                width: 180
                height: 180
                radius: 90
                color: "#ffffff"
                opacity: 0.08
            }

            Text {
                anchors.centerIn: parent
                text: card.product.mark
                color: Theme.onHero
                font.pixelSize: 84
                font.weight: Font.Bold
                font.letterSpacing: -2
            }
        }
    }
}
