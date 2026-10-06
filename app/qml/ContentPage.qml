import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// About and policy pages, written by staff as Markdown.
PageScroll {
    id: page

    readonly property bool policy: Nav.segments[0] === "support"
    readonly property var entry: Store.page(policy ? Nav.segments[1] : "about") || ({ title: "", description: "", body: "", last_reviewed: "" })

    Breadcrumbs {
        items: page.policy ? [{ label: "Support and policies", to: "/support" }, { label: page.entry.title }] : [{ label: page.entry.title }]
    }

    H {
        level: 1
        text: page.entry.title
    }

    P {
        lede: true
        text: page.entry.description
    }

    Markdown {
        source: page.entry.body
    }

    P {
        small: true
        muted: true
        text: "Last reviewed " + Rules.formatDate(page.entry.last_reviewed) + "."
    }
}
