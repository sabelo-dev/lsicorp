import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

PageScroll {
    id: page

    readonly property var doc: Store.doc(Nav.segments[1], Nav.segments[2]) || ({ title: "", summary: "", audience: "", body: "", last_reviewed: "", product_slug: "", slug: "" })
    readonly property var product: Store.product(doc.product_slug) || ({ public_name: "", slug: "" })
    readonly property var siblings: Store.docsFor(doc.product_slug)
    readonly property int position: siblings.findIndex(d => d.slug === doc.slug)
    readonly property var previous: position > 0 ? siblings[position - 1] : null
    readonly property var next: position >= 0 && position < siblings.length - 1 ? siblings[position + 1] : null

    Breadcrumbs {
        items: [
            { label: "Documentation", to: "/docs" },
            { label: page.product.public_name, to: "/docs/" + page.product.slug },
            { label: page.doc.title }
        ]
    }

    H {
        level: 1
        text: page.doc.title
    }

    P {
        lede: true
        text: page.doc.summary
    }

    P {
        small: true
        muted: true
        text: "For: " + page.doc.audience + ". Last reviewed " + Rules.formatDate(page.doc.last_reviewed) + "."
    }

    Markdown {
        source: page.doc.body
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.maximumWidth: Theme.measure
        Layout.topMargin: Theme.s5
        implicitHeight: 1
        color: Theme.border
    }

    H {
        level: 3
        text: "More " + page.product.public_name + " documentation"
    }

    Repeater {
        model: page.siblings

        ListLink {
            required property var modelData
            text: modelData.title + (modelData.slug === page.doc.slug ? " (this page)" : "")
            to: "/docs/" + modelData.product_slug + "/" + modelData.slug
            current: modelData.slug === page.doc.slug
        }
    }

    Flow {
        Layout.fillWidth: true
        Layout.maximumWidth: Theme.measure
        Layout.topMargin: Theme.s3
        spacing: Theme.s3

        AppButton {
            visible: page.previous !== null
            secondary: true
            text: "Previous: " + (page.previous ? page.previous.title : "")
            to: page.previous ? "/docs/" + page.previous.product_slug + "/" + page.previous.slug : ""
        }

        AppButton {
            visible: page.next !== null
            secondary: true
            text: "Next: " + (page.next ? page.next.title : "")
            to: page.next ? "/docs/" + page.next.product_slug + "/" + page.next.slug : ""
        }
    }
}
