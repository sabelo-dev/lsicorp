import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

PageScroll {
    Breadcrumbs {
        items: [{ label: "Downloads" }]
    }

    H {
        level: 1
        text: "Downloads"
    }

    P {
        lede: true
        text: "Official releases, grouped by product and platform. A button appears only for a release that "
              + Store.site.short_name + " has reviewed and published."
    }

    P {
        text: "Every link here goes to an official app store listing, a public web app or an approved download host, and is labelled when it leaves this website. For direct files, compare the SHA-256 checksum shown with the file you receive."
    }

    FieldLabel {
        Layout.topMargin: Theme.s4
        text: "Platform"

        ChipRow {
            id: platform
            label: "Filter by platform"
            options: [{ value: "", text: "All" }].concat(Rules.options(Rules.PLATFORMS))
        }
    }

    Repeater {
        model: Store.products

        ColumnLayout {
            id: group

            required property var modelData

            Layout.fillWidth: true
            spacing: Theme.s3

            H {
                text: group.modelData.public_name
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.s3

                StatusBadge {
                    tone: group.modelData.status
                    label: Rules.PRODUCT_STATUSES[group.modelData.status]
                    prefix: "Status"
                }

                LinkText {
                    text: "About " + group.modelData.public_name
                    to: "/work/" + group.modelData.slug
                    font.pixelSize: Theme.small
                }
            }

            P {
                text: group.modelData.status_note
            }

            PlatformReleases {
                product: group.modelData
                only: platform.value
            }
        }
    }
}
