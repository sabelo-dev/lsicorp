import QtQuick
import QtQuick.Layouts
import LsiTools

Rectangle {
    implicitHeight: column.implicitHeight + 2 * Theme.s6
    color: Theme.surface

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.border
    }

    ColumnLayout {
        id: column
        x: Math.max(Theme.gutter, (parent.width - width) / 2)
        y: Theme.s6
        width: Math.min(Theme.maxWidth, parent.width - 2 * Theme.gutter)
        spacing: Theme.s4

        // The logo is navy, so it always sits on a white plate.
        Rectangle {
            implicitWidth: 196
            implicitHeight: 76
            radius: Theme.controlRadius
            color: "#ffffff"
            border.color: Theme.border
            border.width: Theme.dark ? 0 : 1

            Image {
                anchors.fill: parent
                anchors.margins: 12
                source: "../assets/logo-full.png"
                fillMode: Image.PreserveAspectFit
                mipmap: true
                Accessible.role: Accessible.Graphic
                Accessible.name: "LSI Corp"
            }
        }

        P {
            visible: !!Store.site.tagline
            muted: true
            text: Store.site.tagline || ""
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.s2
            Accessible.role: Accessible.Grouping
            Accessible.name: "Footer"

            Repeater {
                model: [
                    { label: "Services", to: "/services" },
                    { label: "Work", to: "/work" },
                    { label: "About " + Store.site.short_name, to: "/about" },
                    { label: "Contact", to: "/contact" },
                    { label: "Downloads", to: "/downloads" },
                    { label: "Documentation", to: "/docs" },
                    { label: "Support", to: "/support" },
                    { label: "Privacy notice", to: "/support/privacy" },
                    { label: "Terms", to: "/support/terms" },
                    { label: "Accessibility", to: "/support/accessibility" },
                    { label: "Staff sign-in", to: "/admin" }
                ]

                LinkText {
                    required property var modelData
                    text: modelData.label
                    to: modelData.to
                    topPadding: 10
                    bottomPadding: 10
                    font.pixelSize: Theme.small
                }
            }
        }

        P {
            small: true
            muted: true
            text: "© " + new Date().getFullYear() + " " + Store.site.organisation
                  + ". Product status and release details are shown as published by " + Store.site.short_name + "."
        }

        P {
            small: true
            muted: true
            visible: Store.source === "preview"
            text: "Preview data: this copy of the site is not connected to its content service, so it shows the content bundled with the app."
        }
    }
}
