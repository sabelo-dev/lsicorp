import QtQuick
import QtQuick.Layouts
import LsiTools

// What LSI Corp offers, each service backed by the work that demonstrates it.
PageScroll {
    Breadcrumbs {
        items: [{ label: "Services" }]
    }

    H {
        level: 1
        text: "Services"
    }

    P {
        lede: true
        text: Store.site.tagline
    }

    P {
        text: Store.site.short_name + " designs and builds the systems that commerce runs on, and connects them: the platform a customer uses, the delivery that completes the sale and the financial tools around it."
    }

    EmptyState {
        visible: Store.services.length === 0
        text: "Our services will be listed here shortly."
    }

    Repeater {
        model: Store.services

        Card {
            id: block

            required property var modelData
            readonly property var work: Store.workFor(modelData.slug)

            Layout.topMargin: Theme.s3

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s4

                ProductMark {
                    Layout.alignment: Qt.AlignTop
                    mark: block.modelData.mark
                    large: !Theme.narrow
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.s1

                    H {
                        bar: false
                        Layout.topMargin: 0
                        text: block.modelData.name
                    }

                    P {
                        lede: true
                        text: block.modelData.tagline
                    }
                }
            }

            P {
                text: block.modelData.summary
            }

            H {
                level: 4
                visible: block.modelData.offerings.length > 0
                text: "What it includes"
            }

            Repeater {
                model: block.modelData.offerings

                P {
                    required property string modelData
                    text: "• " + modelData
                }
            }

            H {
                level: 4
                visible: block.work.length > 0
                text: "Work that shows it"
            }

            Flow {
                Layout.fillWidth: true
                visible: block.work.length > 0
                spacing: Theme.s2

                Repeater {
                    model: block.work

                    AppButton {
                        required property var modelData

                        text: modelData.public_name
                        to: "/work/" + modelData.slug
                        secondary: true
                        implicitHeight: 44
                    }
                }
            }
        }
    }

    CtaBand {
        title: "Not sure which of these you need?"
        body: "Most projects touch more than one. Describe the problem and we will work out the shape of it with you."
    }
}
