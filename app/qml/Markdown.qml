import QtQuick
import QtQuick.Layouts
import LsiTools

// Renders Markdown content. Links inside rendered text cannot take keyboard
// focus, so they are repeated underneath as ordinary focusable links.
ColumnLayout {
    id: root

    property string source: ""

    readonly property var links: {
        const found = [];
        const pattern = /\[([^\]]+)\]\(([^)\s]+)\)/g;
        let match;
        while ((match = pattern.exec(source)) !== null) {
            const target = match[2];
            if (!found.some(l => l.target === target))
                found.push({ label: match[1], target: target });
        }
        return found;
    }

    Layout.fillWidth: true
    Layout.maximumWidth: Theme.measure
    spacing: Theme.s4

    Text {
        id: rendered

        Layout.fillWidth: true
        text: root.source
        textFormat: Text.MarkdownText
        wrapMode: Text.Wrap
        color: Theme.ink
        linkColor: Theme.accent
        font.pixelSize: Theme.body
        lineHeight: 1.3
        onLinkActivated: link => Nav.follow(link)
        Accessible.role: Accessible.StaticText

        HoverHandler {
            cursorShape: rendered.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }

    Flow {
        Layout.fillWidth: true
        visible: root.links.length > 0
        spacing: Theme.s3

        Text {
            text: "Links on this page:"
            color: Theme.muted
            font.pixelSize: Theme.small
            topPadding: 3
        }

        Repeater {
            model: root.links

            LinkText {
                required property var modelData
                readonly property bool external: modelData.target.charAt(0) !== "/"

                text: modelData.label + (external ? " (external site)" : "")
                font.pixelSize: Theme.small
                onClicked: Nav.follow(modelData.target)
            }
        }
    }
}
