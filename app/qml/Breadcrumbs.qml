import QtQuick
import QtQuick.Layouts
import LsiTools

// Trail from Home to the current page. items: [{ label, to }]; the last has no `to`.
Flow {
    id: root

    property var items: []

    Layout.fillWidth: true
    spacing: Theme.s1
    Accessible.role: Accessible.Grouping
    Accessible.name: "Breadcrumb"

    LinkText {
        text: "Home"
        to: "/"
        font.pixelSize: Theme.small
    }

    Repeater {
        model: root.items

        Row {
            id: crumb

            required property var modelData

            spacing: Theme.s1

            Text {
                text: "›"
                color: Theme.muted
                font.pixelSize: Theme.small
                topPadding: 6
            }

            LinkText {
                visible: !!crumb.modelData.to
                text: crumb.modelData.label
                to: crumb.modelData.to || ""
                font.pixelSize: Theme.small
            }

            Text {
                visible: !crumb.modelData.to
                text: crumb.modelData.label
                color: Theme.ink
                font.pixelSize: Theme.small
                topPadding: 6
            }
        }
    }
}
