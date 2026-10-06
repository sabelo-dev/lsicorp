import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// Documentation index: every product, or one product at /docs/{product}.
PageScroll {
    id: page

    readonly property string only: Nav.segments.length > 1 ? Nav.segments[1] : ""
    readonly property var shown: Store.products.filter(p => only === "" || p.slug === only)

    Breadcrumbs {
        items: page.only === "" ? [{ label: "Documentation" }]
                                : [{ label: "Documentation", to: "/docs" }, { label: page.shown.length ? page.shown[0].public_name : "" }]
    }

    H {
        level: 1
        text: page.only === "" || page.shown.length === 0 ? "Documentation" : page.shown[0].public_name + " documentation"
    }

    P {
        lede: true
        text: "Setup guides, feature explanations and troubleshooting. Each guide says clearly what is available and what is still planned."
    }

    Repeater {
        model: page.shown

        ColumnLayout {
            id: group

            required property var modelData
            readonly property var docs: Store.docsFor(modelData.slug)

            Layout.fillWidth: true
            spacing: Theme.s3

            H {
                visible: page.only === ""
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

            EmptyState {
                visible: group.docs.length === 0
                text: "Documentation for " + group.modelData.public_name + " has not been published yet."
            }

            Repeater {
                model: group.docs

                ListLink {
                    required property var modelData

                    text: modelData.title
                    description: modelData.summary
                    to: "/docs/" + modelData.product_slug + "/" + modelData.slug
                }
            }
        }
    }
}
