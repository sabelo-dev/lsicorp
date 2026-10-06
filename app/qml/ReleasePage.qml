import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// One permanent page per published release, so a version can still be looked
// up after it has been superseded or withdrawn.
PageScroll {
    id: page

    readonly property var release: Store.release(Nav.segments[1], Nav.segments[2], Nav.segments[3]) || ({
        product_slug: "", platform: "other", version: "", channel: "stable", status: "withdrawn", release_date: "",
        destination_type: "store", destination_url: "", compat_minimum: "", compat_device_class: "", compat_dependencies: [],
        steps: [], notes: [], known_issues: [], licence: "", support_route: ""
    })
    readonly property var product: Store.product(release.product_slug) || ({ public_name: "", slug: "" })
    readonly property var newer: release.superseded_by ? Store.release(release.product_slug, release.platform, release.superseded_by) : null
    readonly property string platformName: Rules.PLATFORMS[release.platform]

    Breadcrumbs {
        items: [
            { label: "Downloads", to: "/downloads" },
            { label: page.product.public_name, to: "/work/" + page.product.slug },
            { label: page.release.version + " for " + page.platformName }
        ]
    }

    H {
        level: 1
        text: page.release.destination_type === "web-app" ? page.product.public_name + " on the web"
                                                             : page.product.public_name + " " + page.release.version + " for " + page.platformName
    }

    Notice {
        visible: page.release.status === "withdrawn"
        tone: "withdrawn"
        title: "Withdrawn"
        body: page.release.withdrawn_reason || ""
    }

    Notice {
        visible: page.release.status === "superseded"
        title: "Superseded"
        body: "This version has been replaced by version " + (page.release.superseded_by || "") + "."
    }

    LinkText {
        visible: page.newer !== null
        text: "Go to version " + (page.release.superseded_by || "")
        to: page.newer ? Rules.releasePath(page.newer) : ""
    }

    ReleaseAction {
        release: page.release
        productName: page.product.public_name
    }

    H {
        text: "Release details"
    }

    ReleaseFacts {
        release: page.release
    }

    H {
        text: page.release.destination_type === "web-app" ? "How to open it" : "How to install"
    }

    Repeater {
        model: page.release.steps

        P {
            required property string modelData
            required property int index
            text: (index + 1) + ". " + modelData
        }
    }

    H {
        text: "What changed"
    }

    Repeater {
        model: page.release.notes

        P {
            required property string modelData
            text: "• " + modelData
        }
    }

    H {
        text: "Known issues"
    }

    P {
        visible: page.release.known_issues.length === 0
        text: "No known issues have been recorded for this release."
    }

    Repeater {
        model: page.release.known_issues

        P {
            required property string modelData
            text: "• " + modelData
        }
    }

    H {
        text: "Licence and support"
    }

    P {
        text: page.release.licence
    }

    P {
        text: page.release.support_route
    }

    LinkText {
        text: "View documentation for " + page.product.public_name
        to: "/docs/" + page.product.slug
    }
}
