import QtQuick
import QtQuick.Layouts
import LsiTools

// The company first: who LSI Corp is and what it offers, then the portfolio
// as evidence of the work.
PageScroll {
    id: page

    /// Shown in the hero. Counts come from the content; the founding year is from the company profile.
    readonly property var stats: [
        { value: "2016", label: "Founded" },
        { value: String(Store.services.length), label: "Service areas" },
        { value: String(Store.products.length), label: "Products in the portfolio" },
        { value: String(Store.products.filter(p => p.status === "available").length), label: "Live today" }
    ]
    /// The first live product leads the portfolio section; the rest follow in a grid.
    readonly property var featured: Store.products.find(p => p.status === "available") || (Store.products.length > 0 ? Store.products[0] : null)
    readonly property var others: Store.products.filter(p => featured === null || p.slug !== featured.slug)

    readonly property var values: [
        { title: "Connected design", text: "Digital services, operational workflows and financial tools are brought together, so each part supports the wider customer and business journey." },
        { title: "Practical execution", text: "Products are shaped around everyday needs: finding and selling goods, arranging delivery, accessing media and understanding markets." },
        { title: "Scalable foundations", text: "Systems are built to grow across users, merchants, partners and new service areas over time." }
    ]

    // Navy band with the gold circles of the logo as decoration.
    hero: Rectangle {
        implicitHeight: heroColumn.implicitHeight + (Theme.narrow ? 2 * Theme.s6 : 2 * 80)
        clip: true

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.heroTop
            }

            GradientStop {
                position: 1
                color: Theme.heroBottom
            }
        }

        Repeater {
            model: [
                { x: 0.80, y: -0.25, size: 340, opacity: 0.16, gold: true },
                { x: 0.92, y: 0.55, size: 220, opacity: 0.10, gold: false },
                { x: 0.66, y: 0.78, size: 120, opacity: 0.22, gold: true }
            ]

            Rectangle {
                required property var modelData

                visible: !Theme.narrow || modelData.size > 300
                x: parent.width * modelData.x
                y: parent.height * modelData.y
                width: modelData.size
                height: modelData.size
                radius: modelData.size / 2
                color: modelData.gold ? Theme.gold : "#ffffff"
                opacity: modelData.opacity

                transform: Translate {
                    id: drift
                }

                SequentialAnimation {
                    running: Theme.motion
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: drift
                        property: "y"
                        from: 0
                        to: 18
                        duration: 5200 + modelData.size * 6
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        target: drift
                        property: "y"
                        from: 18
                        to: 0
                        duration: 5200 + modelData.size * 6
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        ColumnLayout {
            id: heroColumn
            x: Math.max(Theme.gutter, (parent.width - width) / 2)
            y: Theme.narrow ? Theme.s6 : 80
            width: Math.min(Theme.maxWidth, parent.width - 2 * Theme.gutter)
            spacing: Theme.s4

            Text {
                Layout.fillWidth: true
                text: Store.site.organisation + "  •  Digital service provider"
                color: Theme.gold
                font.pixelSize: Theme.small
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.5
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: 820
                text: "Connected digital solutions for real-world commerce."
                color: Theme.onHero
                font.pixelSize: Theme.narrow ? 34 : 54
                font.weight: Font.Bold
                font.letterSpacing: -1
                lineHeight: 1.08
                wrapMode: Text.Wrap
                Accessible.role: Accessible.Heading
                Accessible.name: Store.site.name + ". " + text
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: 660
                text: Store.site.description
                color: Theme.onHeroMuted
                font.pixelSize: Theme.narrow ? 17 : Theme.h3
                lineHeight: 1.45
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
                    text: "See our work"
                    to: "/work"
                    secondary: true
                    onBrand: true
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.s6
                spacing: Theme.narrow ? Theme.s5 : Theme.s7

                Repeater {
                    model: page.stats

                    Column {
                        required property var modelData

                        spacing: 2
                        Accessible.role: Accessible.StaticText
                        Accessible.name: modelData.value + " " + modelData.label

                        Text {
                            text: modelData.value
                            color: Theme.onHero
                            font.pixelSize: Theme.narrow ? 28 : 36
                            font.weight: Font.Bold
                            font.letterSpacing: -0.5
                        }

                        Text {
                            text: modelData.label
                            color: Theme.onHeroMuted
                            font.pixelSize: Theme.small
                        }
                    }
                }
            }
        }
    }

    H {
        Layout.topMargin: Theme.s3
        text: "What we do"
    }

    P {
        lede: true
        text: Store.site.short_name + " works across technology, logistics and finance, and connects them, because commerce needs all three."
    }

    CardGrid {
        minColumnWidth: 250

        Repeater {
            model: Store.services

            ServiceCard {
                required property var modelData
                service: modelData
            }
        }
    }

    H {
        text: "How we create value"
    }

    CardGrid {
        Repeater {
            model: page.values

            Card {
                id: value

                required property var modelData
                required property int index

                Layout.fillHeight: true
                Layout.preferredWidth: 1

                Text {
                    text: "0" + (value.index + 1)
                    color: Theme.dark ? Theme.gold : Theme.navy
                    font.pixelSize: Theme.h2
                    font.weight: Font.Bold
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

                Item {
                    Layout.fillHeight: true
                }
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

    CardGrid {
        Layout.topMargin: Theme.s2

        Repeater {
            model: page.others

            ProductCard {
                required property var modelData
                product: modelData
            }
        }
    }

    AppButton {
        text: "View all work"
        to: "/work"
        secondary: true
    }

    CtaBand {}
}
