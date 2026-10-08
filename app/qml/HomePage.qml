import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import LsiTools
import "rules.mjs" as Rules

// The company first: who LSI Corp is and what it offers, with the portfolio
// beside the statement as evidence, then the services, the lead piece of work
// and how the company creates value.
PageScroll {
    id: page

    /// Counts come from the content; the founding year is from the company profile.
    readonly property var stats: [
        { value: "2016", label: "Founded" },
        { value: String(Store.services.length), label: "Service areas" },
        { value: String(Store.products.length), label: "Products in the portfolio" },
        { value: String(Store.products.filter(p => p.status === "available").length), label: "Live today" }
    ]
    /// The first live product leads the portfolio section.
    readonly property var featured: Store.products.find(p => p.status === "available") || (Store.products.length > 0 ? Store.products[0] : null)

    readonly property var values: [
        { title: "Connected design", text: "Digital services, operational workflows and financial tools are brought together, so each part supports the wider customer and business journey." },
        { title: "Practical execution", text: "Products are shaped around everyday needs: finding and selling goods, arranging delivery, accessing media and understanding markets." },
        { title: "Scalable foundations", text: "Systems are built to grow across users, merchants, partners and new service areas over time." }
    ]

    // A flat navy band: the statement on one side, the portfolio as a compact
    // index on the other. On a small screen the index follows the statement.
    hero: Rectangle {
        id: band

        readonly property bool split: Theme.viewWidth >= 960
        readonly property int pad: Theme.narrow ? Theme.s6 : 72
        readonly property real inner: Math.min(Theme.maxWidth, width - 2 * Theme.gutter)
        readonly property real edge: Math.max(Theme.gutter, (width - inner) / 2)

        implicitHeight: 2 * pad + (split ? Math.max(statement.implicitHeight, index.implicitHeight)
                                         : statement.implicitHeight + Theme.s6 + index.implicitHeight)
        color: Theme.heroTop

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 2
            color: Theme.gold
        }

        ColumnLayout {
            id: statement
            x: band.edge
            y: band.pad
            width: band.split ? band.inner * 0.56 : band.inner
            spacing: Theme.s4

            Text {
                Layout.fillWidth: true
                text: Store.site.organisation + "  /  Digital service provider"
                color: Theme.gold
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: "Connected digital solutions for real-world commerce."
                color: Theme.onHero
                font.pixelSize: Theme.narrow ? 32 : 48
                font.weight: Font.Bold
                font.letterSpacing: Theme.narrow ? -0.8 : -1.6
                lineHeight: 1.06
                wrapMode: Text.Wrap
                Accessible.role: Accessible.Heading
                Accessible.name: Store.site.name + ". " + text
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: 560
                text: Store.site.description
                color: Theme.onHeroMuted
                font.pixelSize: Theme.narrow ? 17 : 18
                lineHeight: 1.5
                wrapMode: Text.Wrap
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.s3
                spacing: Theme.s3

                AppButton {
                    text: "Explore our services"
                    to: "/services"
                    onBrand: true
                }

                AppButton {
                    text: "Talk to " + Store.site.short_name
                    to: "/contact"
                    secondary: true
                    onBrand: true
                }
            }
        }

        // The portfolio, one line each, with its true status.
        Rectangle {
            id: index

            x: band.split ? band.edge + band.inner * 0.62 : band.edge
            y: band.split ? band.pad : band.pad + statement.implicitHeight + Theme.s6
            width: band.split ? band.inner * 0.38 : band.inner
            implicitHeight: rows.implicitHeight
            height: implicitHeight
            radius: Theme.radius
            color: Theme.heroPanel
            border.width: 1
            border.color: Theme.heroLine

            ColumnLayout {
                id: rows
                width: parent.width
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Theme.s4
                    Layout.bottomMargin: Theme.s3

                    Text {
                        Layout.fillWidth: true
                        text: "Our work"
                        color: Theme.onHeroMuted
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2
                        Accessible.role: Accessible.Heading
                        Accessible.name: text
                    }

                    Text {
                        text: Store.products.length + " products"
                        color: Theme.onHeroMuted
                        font.pixelSize: 13
                    }
                }

                Repeater {
                    model: Store.products

                    T.AbstractButton {
                        id: row

                        required property var modelData
                        readonly property string status: Rules.PRODUCT_STATUSES[modelData.status]

                        Layout.fillWidth: true
                        implicitHeight: 60
                        focusPolicy: Qt.StrongFocus
                        Accessible.role: Accessible.Link
                        Accessible.name: modelData.public_name + ", " + modelData.category + ", status: " + status
                        onClicked: Nav.go("/work/" + modelData.slug)
                        Keys.onReturnPressed: click()
                        Keys.onEnterPressed: click()

                        background: Rectangle {
                            color: row.hovered || row.down ? Theme.heroPanel : "transparent"
                            border.width: row.visualFocus ? 2 : 0
                            border.color: Theme.onHero

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.heroLine
                            }
                        }

                        contentItem: RowLayout {
                            spacing: Theme.s3

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: Theme.s4
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.public_name
                                    color: Theme.onHero
                                    font.pixelSize: Theme.label
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.category
                                    color: Theme.onHeroMuted
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }

                            // Status in words; the dot only reinforces it.
                            Row {
                                spacing: 6

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: row.modelData.status === "available" ? Theme.gold : "transparent"
                                    border.width: 1
                                    border.color: row.modelData.status === "available" ? Theme.gold : Theme.onHeroMuted
                                }

                                Text {
                                    text: row.status
                                    color: row.modelData.status === "available" ? Theme.onHero : Theme.onHeroMuted
                                    font.pixelSize: 13
                                }
                            }

                            Text {
                                Layout.rightMargin: Theme.s4
                                text: "›"
                                color: Theme.onHeroMuted
                                font.pixelSize: 18
                            }
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    // Key facts as one ruled strip.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: facts.implicitHeight
        radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        GridLayout {
            id: facts
            width: parent.width
            columns: Theme.narrow ? 2 : 4
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: page.stats

                Item {
                    id: cell

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    implicitHeight: fact.implicitHeight + 2 * Theme.s4
                    Accessible.role: Accessible.StaticText
                    Accessible.name: modelData.value + " " + modelData.label

                    // Rules between cells, none on the outer edge.
                    Rectangle {
                        visible: cell.index % facts.columns !== 0
                        width: 1
                        height: parent.height
                        color: Theme.border
                    }

                    Rectangle {
                        visible: cell.index >= facts.columns
                        width: parent.width
                        height: 1
                        color: Theme.border
                    }

                    Column {
                        id: fact
                        x: Theme.s4
                        y: Theme.s4
                        width: parent.width - 2 * Theme.s4
                        spacing: 2

                        Text {
                            text: cell.modelData.value
                            color: Theme.ink
                            font.pixelSize: Theme.narrow ? 24 : 28
                            font.weight: Font.Bold
                            font.letterSpacing: -0.6
                        }

                        Text {
                            width: parent.width
                            text: cell.modelData.label
                            color: Theme.muted
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    H {
        text: "What we do"
    }

    P {
        lede: true
        text: Store.site.short_name + " works across technology, logistics and finance, and connects them, because commerce needs all three."
    }

    CardGrid {
        minColumnWidth: 240
        columnSpacing: Theme.s4
        rowSpacing: Theme.s4

        Repeater {
            model: Store.services

            ServiceCard {
                required property var modelData
                service: modelData
            }
        }
    }

    H {
        text: "Selected work"
    }

    P {
        lede: true
        text: "Products designed and built by " + Store.site.short_name + ". Each one is shown with its true status."
    }

    Repeater {
        model: page.featured ? 1 : 0

        FeatureWork {
            product: page.featured
        }
    }

    AppButton {
        text: "View all work"
        to: "/work"
        secondary: true
    }

    H {
        text: "How we create value"
    }

    // Three numbered columns under a rule, without boxes.
    CardGrid {
        minColumnWidth: 260
        columnSpacing: Theme.s6

        Repeater {
            model: page.values

            ColumnLayout {
                id: value

                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Theme.s2

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.controlBorder
                }

                Text {
                    Layout.topMargin: Theme.s2
                    text: "0" + (value.index + 1)
                    color: Theme.muted
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    Accessible.ignored: true
                }

                H {
                    level: 3
                    Layout.topMargin: 0
                    text: value.modelData.title
                }

                P {
                    text: value.modelData.text
                }
            }
        }
    }

    CtaBand {}
}
