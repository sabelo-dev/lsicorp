import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// The portfolio: products designed and built by LSI Corp. It can be searched
// and filtered, and the address carries that view (/work?q=…&status=…), so a
// filtered list can be shared, bookmarked or returned to with Back.
PageScroll {
    id: page

    readonly property var view: ({ q: search.text.trim(), service: service.value, status: status.value, platform: platform.value, sort: sort.value })
    readonly property var shown: Rules.filterCatalog(Store.products, Store.releases, Store.services, view)
    readonly property var facets: Rules.catalogFacets(Store.products, Store.releases)
    readonly property int filterCount: Rules.activeFilterCount(view)
    readonly property bool narrowed: filterCount > 0 || view.q !== ""
    readonly property string summary: shown.length === Store.products.length
                                      ? "Showing all " + Store.products.length + " projects"
                                      : "Showing " + shown.length + " of " + Store.products.length + " projects"
    /// On a small screen the filters sit behind a button that shows how many are in use.
    property bool filtersOpen: false
    /// The last result count read out to assistive technology.
    property string announced: ""

    /// Called for the "/" key (see Main): puts the keyboard in the search field.
    function focusSearch() {
        search.forceActiveFocus();
    }

    function clearAll() {
        search.text = "";
        service.value = "";
        status.value = "";
        platform.value = "";
    }

    /// Takes the view from the address: on arrival, and when Back or a link changes it.
    function readAddress() {
        const q = Nav.query;
        const known = (value, options) => options.some(o => o.value === value) ? value : "";
        if ((q.q || "") !== view.q)
            search.text = q.q || "";
        service.value = known(q.service || "", service.options);
        status.value = known(q.status || "", status.options);
        platform.value = known(q.platform || "", platform.options);
        sort.value = known(q.sort || "", sort.options);
    }

    Component.onCompleted: {
        readAddress();
        announced = shown.length === 0 ? "No projects match" : summary;
    }
    onViewChanged: writeAddress.restart()

    Connections {
        target: Nav

        function onQueryChanged() {
            if (Nav.path === "/work" || Nav.path === "/products")
                page.readAddress();
        }
    }

    // Typing is reflected in the address after a pause, not on every keystroke.
    Timer {
        id: writeAddress
        interval: 300
        onTriggered: {
            if (Nav.path !== "/work" && Nav.path !== "/products")
                return;
            Nav.setQuery(page.view);
            const result = page.shown.length === 0 ? "No projects match" : page.summary;
            if (result !== page.announced) {
                page.announced = result;
                page.Accessible.announce(result);
            }
        }
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
        Layout.maximumWidth: 560
        text: "Search our work"
        hint: Theme.narrow ? "" : "Press / to search from anywhere on this page, and Esc to clear."

        SearchField {
            id: search
            placeholderText: "For example: commerce, Windows, available"
            Accessible.name: "Search our work"
            Accessible.description: "Results update as you type"
        }
    }

    AppButton {
        visible: Theme.narrow
        text: (page.filtersOpen ? "Hide filters" : "Filters") + (page.filterCount > 0 ? " (" + page.filterCount + " on)" : "")
        secondary: true
        Accessible.name: text + (page.filtersOpen ? ", expanded" : ", collapsed")
        onClicked: page.filtersOpen = !page.filtersOpen
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !Theme.narrow || page.filtersOpen
        spacing: Theme.s4

        FieldLabel {
            text: "Service"

            ChipRow {
                id: service
                label: "Filter by service"
                options: [{ value: "", text: "All" }].concat(Store.services.map(s => ({ value: s.slug, text: s.name })))
            }
        }

        GridLayout {
            id: grid

            /// Share of the page width for a group when the three sit side by side.
            /// Taken from the window, not from this layout, so that sizing does not feed back into itself.
            function share(part) {
                const available = Math.min(Theme.maxWidth, Theme.viewWidth - 2 * Theme.gutter);
                return columns === 1 ? -1 : (available - 2 * columnSpacing) * part;
            }

            Layout.fillWidth: true
            columns: Theme.viewWidth >= 1000 ? 3 : 1
            columnSpacing: Theme.s5
            rowSpacing: Theme.s4

            FieldLabel {
                visible: page.facets.statuses.length > 1
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: grid.columns === 1
                Layout.preferredWidth: grid.share(0.44)
                text: "Status"

                ChipRow {
                    id: status
                    label: "Filter by status"
                    options: [{ value: "", text: "Any" }].concat(page.facets.statuses.map(s => ({ value: s, text: Rules.PRODUCT_STATUSES[s] })))
                }
            }

            FieldLabel {
                visible: page.facets.platforms.length > 1
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: grid.columns === 1
                Layout.preferredWidth: grid.share(0.28)
                text: "Platform"

                ChipRow {
                    id: platform
                    label: "Filter by platform"
                    options: [{ value: "", text: "Any" }].concat(page.facets.platforms.map(p => ({ value: p, text: Rules.PLATFORMS[p] })))
                }
            }

            FieldLabel {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: grid.columns === 1
                Layout.preferredWidth: grid.share(0.28)
                text: "Sort"

                ChipRow {
                    id: sort
                    label: "Sort order"
                    options: Rules.options(Rules.CATALOG_SORTS)
                }
            }
        }
    }

    // The count, and the way back to everything, stay in one place above the results.
    Flow {
        Layout.fillWidth: true
        spacing: Theme.s3

        P {
            width: Math.min(implicitWidth, parent.width)
            topPadding: 6
            bottomPadding: 6
            small: true
            muted: true
            text: page.summary + (page.filterCount > 0 ? ", " + page.filterCount + (page.filterCount === 1 ? " filter on" : " filters on") : "")
        }

        LinkText {
            // With no results, the button under the explanation does this job.
            visible: page.narrowed && page.shown.length > 0
            text: "Clear search and filters"
            font.pixelSize: Theme.small
            onClicked: page.clearAll()
        }
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
        text: (page.view.q !== "" ? "No projects match “" + page.view.q + "”" : "No projects match")
              + (page.filterCount > 0 ? " with the chosen filters" : "")
              + ". Try a product name, a category or a platform, or clear the search and filters to see everything."
    }

    AppButton {
        visible: page.shown.length === 0
        text: "Clear search and filters"
        secondary: true
        onClicked: {
            page.clearAll();
            search.forceActiveFocus();
        }
    }

    CtaBand {
        title: "Planning something similar?"
        body: Store.site.short_name + " builds platforms like these. Tell us what you are working on."
    }
}
