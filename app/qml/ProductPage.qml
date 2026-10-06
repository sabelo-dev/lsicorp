import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// One template for every product: overview, capabilities, requirements,
// getting started, help and release history.
PageScroll {
    id: page

    readonly property var product: Store.product(Nav.segments[1]) || ({
        slug: "", public_name: "", internal_name: "", mark: "", tagline: "", summary: "", status: "in-development",
        status_note: "", audiences: [], capabilities: [], requirements: [], platforms: [], limitations: [], getting_started: ""
    })
    readonly property var releases: Store.releasesFor(product.slug)
    readonly property var docs: Store.docsFor(product.slug)
    readonly property var faqs: Store.faqsFor(product.slug)
    readonly property bool hasRelease: Rules.availableReleases(releases, product.slug, "").length > 0

    Breadcrumbs {
        items: [{ label: "Work", to: "/work" }, { label: page.product.public_name }]
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.s4

        ProductMark {
            Layout.alignment: Qt.AlignTop
            mark: page.product.mark
            large: !Theme.narrow
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            H {
                level: 1
                text: page.product.public_name
            }

            P {
                visible: page.product.internal_name !== page.product.public_name
                muted: true
                text: "Also known as " + page.product.internal_name
            }

            P {
                lede: true
                text: page.product.tagline
            }

            // The services this piece of work demonstrates.
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.s2
                visible: (page.product.services || []).length > 0
                spacing: Theme.s2

                Repeater {
                    model: (page.product.services || []).map(slug => Store.service(slug)).filter(s => s !== null)

                    AppButton {
                        required property var modelData

                        text: modelData.name
                        to: "/services"
                        secondary: true
                        implicitHeight: 40
                        Accessible.name: "Service: " + modelData.name
                    }
                }
            }
        }
    }

    // Availability: status in words next to the primary action.
    Card {
        Layout.topMargin: Theme.s3

        StatusBadge {
            tone: page.product.status
            label: Rules.PRODUCT_STATUSES[page.product.status]
            prefix: "Status"
        }

        P {
            text: page.product.status_note
        }

        PlatformReleases {
            visible: page.hasRelease
            product: page.product
        }

        EmptyState {
            visible: !page.hasRelease
            text: (page.product.status === "coming-soon" ? "Coming Soon. " : "No release available yet. ")
                  + "There is nothing to download or open for " + page.product.public_name + " at the moment."
        }

        AppButton {
            visible: page.docs.length > 0
            text: "View documentation"
            to: "/docs/" + page.product.slug
            secondary: true
        }
    }

    // On this page: jump to a section.
    Flow {
        Layout.fillWidth: true
        Layout.topMargin: Theme.s4
        spacing: Theme.s2
        Accessible.role: Accessible.Grouping
        Accessible.name: "On this page"

        Repeater {
            model: [
                { label: "Overview", target: overviewHeading },
                { label: "Capabilities", target: capabilitiesHeading },
                { label: "Requirements", target: requirementsHeading },
                { label: "Getting started", target: startHeading },
                { label: "Help", target: helpHeading },
                { label: "Release history", target: historyHeading }
            ]

            AppButton {
                required property var modelData

                text: modelData.label
                secondary: true
                implicitHeight: 40
                Accessible.name: "Jump to " + modelData.label
                onClicked: page.scrollToItem(modelData.target)
            }
        }
    }

    H {
        id: overviewHeading
        text: "Overview"
    }

    P {
        text: page.product.summary
    }

    Notice {
        visible: !!page.product.notice_title
        title: page.product.notice_title || ""
        body: page.product.notice_body || ""
    }

    H {
        level: 3
        text: "Who it is for"
    }

    Repeater {
        model: page.product.audiences

        ColumnLayout {
            id: audience

            required property var modelData

            Layout.fillWidth: true
            spacing: 0

            H {
                level: 4
                text: audience.modelData.name
            }

            P {
                text: audience.modelData.description
            }
        }
    }

    H {
        id: capabilitiesHeading
        text: "Capabilities"
    }

    P {
        text: "Capabilities are listed by what you can use today and what is planned. A planned capability is not available and may change before release."
    }

    P {
        visible: !!page.product.platform_note
        text: page.product.platform_note || ""
    }

    Repeater {
        model: [
            { key: "available", title: "Available now", empty: "No capabilities have been released yet." },
            { key: "planned", title: "Planned", empty: "No further capabilities are planned at the moment." }
        ]

        ColumnLayout {
            id: group

            required property var modelData
            readonly property var items: page.product.capabilities.filter(c => c.availability === modelData.key)

            Layout.fillWidth: true
            spacing: Theme.s3

            H {
                level: 3
                text: group.modelData.title
            }

            EmptyState {
                visible: group.items.length === 0
                text: group.modelData.empty
            }

            Repeater {
                model: group.items

                ColumnLayout {
                    id: capability

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Theme.s1

                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.s2

                        Text {
                            text: capability.modelData.name
                            color: Theme.ink
                            font.pixelSize: Theme.body
                            font.weight: Font.Bold
                            Accessible.role: Accessible.Heading
                            Accessible.name: text
                        }

                        StatusBadge {
                            tone: capability.modelData.availability
                            label: capability.modelData.availability === "available" ? "Available" : "Planned"
                        }
                    }

                    P {
                        visible: !!capability.modelData.group
                        small: true
                        muted: true
                        text: capability.modelData.group || ""
                    }

                    P {
                        text: capability.modelData.description
                    }

                    P {
                        visible: !!capability.modelData.platformNote
                        small: true
                        muted: true
                        text: capability.modelData.platformNote || ""
                    }
                }
            }
        }
    }

    H {
        id: requirementsHeading
        text: "Requirements"
    }

    Facts {
        model: page.product.requirements.map(r => ({ label: r.label, value: r.detail }))
    }

    H {
        id: startHeading
        text: "Getting started"
    }

    P {
        text: page.product.getting_started
    }

    EmptyState {
        visible: page.docs.length === 0
        text: "Documentation for " + page.product.public_name + " has not been published yet."
    }

    Repeater {
        model: page.docs

        ListLink {
            required property var modelData

            text: modelData.title
            description: modelData.summary
            to: "/docs/" + modelData.product_slug + "/" + modelData.slug
        }
    }

    H {
        id: helpHeading
        text: "Help"
    }

    H {
        level: 3
        text: "Frequently asked questions"
    }

    EmptyState {
        visible: page.faqs.length === 0
        text: "No questions have been published for " + page.product.public_name + " yet."
    }

    Repeater {
        model: page.faqs

        Disclosure {
            required property var modelData

            title: modelData.question
            body: modelData.answer
            note: modelData.escalation ? "Still stuck? " + modelData.escalation : ""
        }
    }

    H {
        level: 3
        visible: page.product.limitations.length > 0
        text: "Known limitations"
    }

    Repeater {
        model: page.product.limitations

        P {
            required property string modelData
            text: "• " + modelData
        }
    }

    H {
        level: 3
        text: "Support"
    }

    P {
        text: "If the documentation does not answer your question, use the support route for " + page.product.public_name + "."
    }

    Flow {
        Layout.fillWidth: true
        spacing: Theme.s4

        LinkText {
            text: "Support for " + page.product.public_name
            onClicked: Nav.follow(page.product.support_url || "/support")
        }

        LinkText {
            text: "Privacy notice"
            onClicked: Nav.follow(page.product.privacy_url || "/support/privacy")
        }
    }

    Card {
        Layout.topMargin: Theme.s6
        Layout.maximumWidth: Theme.measure

        H {
            level: 3
            Layout.topMargin: 0
            text: "Planning something similar?"
        }

        P {
            text: Store.site.short_name + " designs and builds platforms like this one. Tell us what you are working on."
        }

        AppButton {
            text: "Talk to " + Store.site.short_name
            to: "/contact"
        }
    }

    H {
        id: historyHeading
        text: "Release history"
    }

    EmptyState {
        visible: page.releases.length === 0
        text: "No releases have been published for " + page.product.public_name + "."
    }

    Repeater {
        model: page.releases

        Card {
            id: history

            required property var modelData

            Layout.maximumWidth: Theme.measure
            padding: Theme.s4
            to: Rules.releasePath(modelData)

            Flow {
                Layout.fillWidth: true
                spacing: Theme.s3

                LinkText {
                    text: history.modelData.version + " for " + Rules.PLATFORMS[history.modelData.platform]
                    to: Rules.releasePath(history.modelData)
                    strong: true
                }

                StatusBadge {
                    tone: history.modelData.status
                    label: Rules.RELEASE_STATUSES[history.modelData.status]
                }
            }

            P {
                small: true
                muted: true
                text: Rules.CHANNELS[history.modelData.channel] + " channel, released " + Rules.formatDate(history.modelData.release_date)
                      + " (" + Store.site.date_timezone + ")"
            }

            P {
                small: true
                text: history.modelData.notes.join(" ")
            }
        }
    }
}
