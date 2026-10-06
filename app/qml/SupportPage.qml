import QtQuick
import QtQuick.Layouts
import LsiTools

PageScroll {
    id: page

    readonly property bool hasContact: !!Store.site.support_email || !!Store.site.support_url

    Breadcrumbs {
        items: [{ label: "Support and policies" }]
    }

    H {
        level: 1
        text: "Support and policies"
    }

    P {
        lede: true
        text: "Help with a product in our portfolio. Start with its documentation; if that does not solve it, contact " + Store.site.short_name + " support."
    }

    H {
        text: "Help by product"
    }

    Repeater {
        model: Store.products

        ListLink {
            required property var modelData
            text: modelData.public_name + " documentation"
            description: "Guides, questions and troubleshooting."
            to: "/docs/" + modelData.slug
        }
    }

    H {
        text: "Contact support"
    }

    EmptyState {
        visible: !page.hasContact
        text: "Support contact details have not been published yet."
    }

    P {
        visible: !!Store.site.support_email
        text: "Email: " + (Store.site.support_email || "")
    }

    LinkText {
        visible: !!Store.site.support_url
        text: "Open the support page"
        onClicked: Nav.follow(Store.site.support_url)
    }

    P {
        text: "Never send passwords or payment details when asking for help. This website does not ask for product sign-in details."
    }

    H {
        text: "Policies"
    }

    Repeater {
        model: [
            { label: "Privacy notice", to: "/support/privacy" },
            { label: "Terms of use", to: "/support/terms" },
            { label: "Accessibility statement", to: "/support/accessibility" }
        ]

        ListLink {
            required property var modelData
            text: modelData.label
            to: modelData.to
        }
    }
}
