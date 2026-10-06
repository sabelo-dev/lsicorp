import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Templates as T
import LsiTools

ApplicationWindow {
    id: window

    width: 1200
    height: 800
    visible: true
    title: page.title + " | " + Store.site.name
    color: Theme.bg

    // Controls from the Basic style take their colours from here.
    palette.window: Theme.bg
    palette.windowText: Theme.ink
    palette.base: Theme.surface
    palette.alternateBase: Theme.surfaceAlt
    palette.text: Theme.ink
    palette.button: Theme.surfaceAlt
    palette.buttonText: Theme.ink
    palette.highlight: Theme.accent
    palette.highlightedText: Theme.accentInk
    palette.placeholderText: Theme.muted
    palette.mid: Theme.muted
    palette.dark: Theme.ink
    palette.light: Theme.surface
    palette.midlight: Theme.border
    palette.link: Theme.accent
    palette.linkVisited: Theme.accent

    /// The page for the current path: { file, title }.
    readonly property var page: {
        const s = Nav.segments;
        if (Store.state === "loading")
            return { file: "LoadingPage.qml", title: "Loading" };
        if (Store.state === "error")
            return { file: "ErrorPage.qml", title: "Content unavailable" };
        if (s.length === 0)
            return { file: "HomePage.qml", title: Store.site.tagline || "Home" };
        switch (s[0]) {
        case "services":
            if (s.length === 1)
                return { file: "ServicesPage.qml", title: "Services" };
            break;
        case "work":
        case "products":    // the earlier address for the same pages
            if (s.length === 1)
                return { file: "WorkPage.qml", title: "Our work" };
            if (s.length === 2 && Store.product(s[1]))
                return { file: "ProductPage.qml", title: Store.product(s[1]).public_name };
            break;
        case "contact":
            if (s.length === 1)
                return { file: "ContactPage.qml", title: "Contact" };
            break;
        case "downloads":
            if (s.length === 1)
                return { file: "DownloadsPage.qml", title: "Downloads" };
            if (s.length === 4 && Store.release(s[1], s[2], s[3]))
                return { file: "ReleasePage.qml", title: Store.product(s[1]).public_name + " " + s[3] };
            break;
        case "docs":
            if (s.length === 1 || (s.length === 2 && Store.product(s[1])))
                return { file: "DocsPage.qml", title: s.length === 2 ? Store.product(s[1]).public_name + " documentation" : "Documentation" };
            if (s.length === 3 && Store.doc(s[1], s[2]))
                return { file: "DocPage.qml", title: Store.doc(s[1], s[2]).title };
            break;
        case "about":
            if (s.length === 1)
                return { file: "ContentPage.qml", title: "About " + Store.site.short_name };
            break;
        case "support":
            if (s.length === 1)
                return { file: "SupportPage.qml", title: "Support and policies" };
            if (s.length === 2 && Store.page(s[1]) && s[1] !== "about")
                return { file: "ContentPage.qml", title: Store.page(s[1]).title };
            break;
        case "admin":
            if (s.length <= 3)
                return { file: "AdminPage.qml", title: "Staff" };
            break;
        }
        return { file: "NotFoundPage.qml", title: "Page not found" };
    }

    onTitleChanged: Platform.setTitle(title)
    Component.onCompleted: Platform.setTitle(title)

    Binding {
        target: Theme
        property: "viewWidth"
        value: window.width
    }

    readonly property var destinations: [
        { label: "Services", to: "/services" },
        { label: "Work", to: "/work" },
        { label: "About", to: "/about" },
        { label: "Contact", to: "/contact" }
    ]
    /// On a small screen the destinations move into a menu.
    readonly property bool compact: width < 720

    function isCurrent(to) {
        return Nav.path === to || Nav.path.startsWith(to + "/");
    }

    header: Rectangle {
        implicitHeight: 68
        color: Theme.surface

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.border
        }

        RowLayout {
            x: Math.max(Theme.gutter, (parent.width - width) / 2)
            width: Math.min(Theme.maxWidth, parent.width - 2 * Theme.gutter)
            height: parent.height
            spacing: Theme.s2

            // Logo and site name: home.
            T.AbstractButton {
                id: brand

                implicitWidth: brandRow.implicitWidth + Theme.s3
                implicitHeight: 52
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Link
                Accessible.name: Store.site.name + ", home"
                onClicked: Nav.go("/")
                Keys.onReturnPressed: click()
                Keys.onEnterPressed: click()

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.controlRadius
                    border.width: brand.visualFocus ? 3 : 0
                    border.color: Theme.focus
                }

                contentItem: Row {
                    id: brandRow
                    spacing: Theme.s3

                    // The mark is navy, so it sits on a white tile in both colour schemes.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44
                        radius: 11
                        color: "#ffffff"
                        border.width: Theme.dark ? 0 : 1
                        border.color: Theme.border

                        Image {
                            anchors.fill: parent
                            anchors.margins: 5
                            source: "../assets/logo-mark.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Store.site.name
                        color: Theme.dark ? Theme.ink : Theme.navy
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        font.letterSpacing: -0.3
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Repeater {
                model: window.compact ? [] : window.destinations

                NavPill {
                    required property var modelData

                    text: modelData.label
                    to: modelData.to
                    current: window.isCurrent(modelData.to)
                }
            }

            // Menu button, small screens only.
            T.AbstractButton {
                id: menuButton

                visible: window.compact
                implicitWidth: Theme.touch
                implicitHeight: Theme.touch
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.Button
                Accessible.name: "Menu"
                onClicked: menu.open()
                Keys.onReturnPressed: click()
                Keys.onEnterPressed: click()

                background: Rectangle {
                    radius: Theme.controlRadius
                    color: menuButton.hovered || menuButton.down ? Theme.surfaceAlt : "transparent"
                    border.width: menuButton.visualFocus ? 3 : 1
                    border.color: menuButton.visualFocus ? Theme.focus : Theme.border
                }

                contentItem: Item {
                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Repeater {
                            model: 3

                            Rectangle {
                                width: 22
                                height: 2
                                radius: 1
                                color: Theme.ink
                            }
                        }
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    // Slides in from the right; can also be swiped closed.
    Drawer {
        id: menu

        edge: Qt.RightEdge
        width: Math.min(340, window.width * 0.86)
        height: window.height
        interactive: window.compact

        background: Rectangle {
            color: Theme.surface
        }

        onOpened: firstItem.forceActiveFocus()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.s4
            spacing: Theme.s2

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    leftPadding: Theme.s4
                    text: "Menu"
                    color: Theme.muted
                    font.pixelSize: Theme.small
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1
                }

                AppButton {
                    text: "Close"
                    secondary: true
                    onClicked: menu.close()
                }
            }

            NavPill {
                id: firstItem
                Layout.fillWidth: true
                wide: true
                text: "Home"
                to: "/"
                current: Nav.path === "/"
                onClicked: menu.close()
            }

            Repeater {
                model: window.destinations

                NavPill {
                    required property var modelData

                    Layout.fillWidth: true
                    wide: true
                    text: modelData.label
                    to: modelData.to
                    current: window.isCurrent(modelData.to)
                    onClicked: menu.close()
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    Loader {
        anchors.fill: parent
        source: window.page.file
        focus: true
    }
}
