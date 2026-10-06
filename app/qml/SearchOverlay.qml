import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Templates as T
import LsiTools

// Search across the whole site from anywhere (Ctrl+K or "/"): services, work,
// documentation and pages. Arrow keys move, Enter opens, Escape closes.
Popup {
    id: root

    property int current: 0

    /// Everything that can be found, built from the content the site has loaded.
    readonly property var index: {
        const items = [
            { title: "Services", kind: "Page", to: "/services", text: "what we do offer digital platforms logistics financial technology" },
            { title: "Our work", kind: "Page", to: "/work", text: "portfolio products projects" },
            { title: "Contact", kind: "Page", to: "/contact", text: "enquiry get in touch email message project" },
            { title: "Downloads", kind: "Page", to: "/downloads", text: "releases install apps" },
            { title: "Documentation", kind: "Page", to: "/docs", text: "guides help" },
            { title: "Support and policies", kind: "Page", to: "/support", text: "help privacy terms accessibility" }
        ];
        Store.services.forEach(s => items.push({ title: s.name, kind: "Service", to: "/services", text: s.tagline + " " + s.summary }));
        Store.products.forEach(p => items.push({ title: p.public_name, kind: "Work", to: "/work/" + p.slug,
                                                 text: p.internal_name + " " + p.category + " " + p.tagline + " " + p.summary }));
        Store.docs.forEach(d => {
            const product = Store.product(d.product_slug);
            items.push({ title: d.title, kind: "Guide" + (product ? " · " + product.public_name : ""),
                         to: "/docs/" + d.product_slug + "/" + d.slug, text: d.summary });
        });
        Store.pages.forEach(p => items.push({ title: p.title, kind: "Page", to: p.slug === "about" ? "/about" : "/support/" + p.slug, text: p.description }));
        return items;
    }

    readonly property var results: {
        const terms = field.text.toLowerCase().split(/\s+/).filter(t => t.length > 0);
        if (terms.length === 0)
            return index.slice(0, 6);
        // A match in the title outranks a match in the description.
        return index.map(item => {
            const title = item.title.toLowerCase();
            const all = title + " " + item.kind.toLowerCase() + " " + item.text.toLowerCase();
            if (!terms.every(t => all.indexOf(t) >= 0))
                return null;
            return { item: item, score: terms.filter(t => title.indexOf(t) >= 0).length * 2 + (title.indexOf(terms[0]) === 0 ? 1 : 0) };
        }).filter(r => r !== null).sort((a, b) => b.score - a.score).slice(0, 8).map(r => r.item);
    }

    function go(item) {
        close();
        Nav.go(item.to);
    }

    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Theme.narrow ? Theme.s4 : 96
    width: Math.min(640, parent.width - 2 * Theme.s4)
    padding: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    onOpened: {
        field.text = "";
        current = 0;
        field.forceActiveFocus();
    }
    onResultsChanged: current = 0

    Overlay.modal: Rectangle {
        color: Theme.scrim
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.fast
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Theme.fast
        }
    }

    background: Rectangle {
        radius: Theme.radius
        color: Theme.surface
        border.color: Theme.border

        Shadow {
            radius: Theme.radius
            elevation: 3
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.s3
            spacing: Theme.s2

            Icon {
                Layout.leftMargin: Theme.s2
                name: "search"
                color: Theme.muted
            }

            TextField {
                id: field

                Layout.fillWidth: true
                implicitHeight: Theme.touch
                placeholderText: "Search services, work and guides"
                placeholderTextColor: Theme.muted
                color: Theme.ink
                font.pixelSize: 18
                background: null
                Accessible.name: "Search the site"

                Keys.onDownPressed: root.current = Math.min(root.results.length - 1, root.current + 1)
                Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
                onAccepted: if (root.results.length > 0) root.go(root.results[root.current])
            }

            IconButton {
                glyph: "close"
                label: "Close search"
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        Text {
            Layout.fillWidth: true
            Layout.margins: Theme.s5
            visible: root.results.length === 0
            text: "Nothing matches “" + field.text + "”. Try a product name, a service or a topic."
            color: Theme.muted
            font.pixelSize: Theme.body
            wrapMode: Text.Wrap
            Accessible.role: Accessible.AlertMessage
            Accessible.name: text
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.s2
            visible: root.results.length > 0
            spacing: 2

            Repeater {
                model: root.results.length

                T.AbstractButton {
                    id: row

                    required property int index
                    readonly property var entry: root.results[index]
                    readonly property bool selected: index === root.current

                    Layout.fillWidth: true
                    implicitHeight: 56
                    focusPolicy: Qt.NoFocus
                    Accessible.role: Accessible.Link
                    Accessible.name: entry.title + ", " + entry.kind
                    onClicked: root.go(entry)
                    onHoveredChanged: if (hovered) root.current = index

                    background: Rectangle {
                        radius: Theme.controlRadius
                        color: row.selected ? Theme.primarySoft : "transparent"
                    }

                    contentItem: RowLayout {
                        spacing: Theme.s3

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: Theme.s4
                            text: row.entry.title
                            color: Theme.ink
                            font.pixelSize: Theme.body
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.rightMargin: Theme.s4
                            text: row.entry.kind
                            color: Theme.muted
                            font.pixelSize: Theme.small
                            elide: Text.ElideRight
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
            visible: !Theme.narrow
        }

        Text {
            Layout.fillWidth: true
            Layout.margins: Theme.s3
            Layout.leftMargin: Theme.s5
            visible: !Theme.narrow
            text: "↑ ↓ to move   ·   Enter to open   ·   Esc to close"
            color: Theme.muted
            font.pixelSize: 12
            Accessible.ignored: true
        }
    }
}
