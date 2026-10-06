import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// The portfolio: products designed and built by LSI Corp.
PageScroll {
    id: page

    readonly property var shown: {
        const terms = search.text.toLowerCase().split(/\s+/).filter(t => t.length > 0);
        const wanted = service.value;
        return Store.products.filter(function (p) {
            const haystack = [p.public_name, p.internal_name, p.category, p.tagline, p.summary, Rules.PRODUCT_STATUSES[p.status]]
                .join(" ").toLowerCase();
            return (!wanted || (p.services || []).indexOf(wanted) >= 0) && terms.every(t => haystack.indexOf(t) >= 0);
        });
    }

    Breadcrumbs {
        items: [{ label: "Work" }]
    }

    H {
        level: 1
        text: "Our work"
    }

    P {
        lede: true
        text: "A portfolio of products designed and built by " + Store.site.short_name + "."
    }

    P {
        text: "The projects are at different stages, and each is shown with its true status. Something marked In Development or Coming Soon cannot be used yet."
    }

    FieldLabel {
        Layout.topMargin: Theme.s4
        text: "Service"

        ChipRow {
            id: service
            label: "Filter by service"
            options: [{ value: "", text: "All" }].concat(Store.services.map(s => ({ value: s.slug, text: s.name })))
        }
    }

    FieldLabel {
        Layout.maximumWidth: 520
        text: "Search"

        Input {
            id: search
            placeholderText: "Name, category or keyword"
            Accessible.name: "Search our work"
        }
    }

    P {
        small: true
        muted: true
        text: page.shown.length + " of " + Store.products.length + " projects shown"
    }

    CardGrid {
        visible: page.shown.length > 0

        Repeater {
            model: page.shown

            ProductCard {
                required property var modelData
                product: modelData
            }
        }
    }

    EmptyState {
        visible: page.shown.length === 0
        text: "No projects match. Clear the search or choose a different service."
    }

    AppButton {
        visible: page.shown.length === 0
        text: "Clear filters"
        secondary: true
        onClicked: {
            search.text = "";
            service.value = "";
        }
    }

    CtaBand {
        title: "Planning something similar?"
        body: Store.site.short_name + " builds platforms like these. Tell us what you are working on."
    }
}
