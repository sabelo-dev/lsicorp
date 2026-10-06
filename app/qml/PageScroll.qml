import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Templates as T
import LsiTools

// Scrolling page body: an optional full-width hero, a centred column of
// content, and the site footer. Tuned for touch: a finger drags and flicks
// the page with momentum, a tap that starts a drag does not press a button,
// and a button returns to the top of a long page.
Item {
    id: root

    default property alias content: column.data
    /// Optional band shown edge to edge above the content.
    property Component hero: null

    Flickable {
        id: flick

        anchors.fill: parent
        contentWidth: width
        contentHeight: body.height
        clip: true
        flickableDirection: Flickable.VerticalFlick
        // The page gives a little when dragged past an end, but a mouse wheel
        // or a flick stops cleanly at the end instead of bouncing.
        boundsBehavior: Flickable.DragOverBounds
        boundsMovement: Flickable.StopAtBounds
        flickDeceleration: 2600
        maximumFlickVelocity: 6000
        // Long enough to tell a scroll from a tap, short enough not to feel late.
        pressDelay: 70
        pixelAligned: true

        ScrollBar.vertical: ScrollBar {
            id: bar
            policy: ScrollBar.AsNeeded
            minimumSize: 0.08

            contentItem: Rectangle {
                implicitWidth: bar.hovered || bar.pressed ? 10 : 6
                radius: width / 2
                color: Theme.muted
                opacity: bar.pressed ? 0.9 : bar.active ? 0.6 : 0
            }
        }

        /// Scrolls just far enough to show `item`. Called when a control gains keyboard focus.
        function revealItem(item) {
            const top = item.mapToItem(flick.contentItem, 0, 0).y;
            const bottom = top + item.height;
            const limit = Math.max(0, contentHeight - height);
            if (top < contentY + Theme.s5)
                contentY = Math.max(0, Math.min(limit, top - Theme.s5));
            else if (bottom > contentY + height - Theme.s5)
                contentY = Math.max(0, Math.min(limit, bottom - height + Theme.s5));
        }

        function scrollBy(distance) {
            contentY = Math.max(0, Math.min(Math.max(0, contentHeight - height), contentY + distance));
        }

        NumberAnimation {
            id: toTop
            target: flick
            property: "contentY"
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }

        Column {
            id: body
            width: flick.width

            Loader {
                id: heroSlot
                width: parent.width
                sourceComponent: root.hero
            }

            Item {
                width: parent.width
                height: Math.max(column.implicitHeight + Theme.s6 + Theme.s7, flick.height - footer.height - heroSlot.height)

                ColumnLayout {
                    id: column
                    x: Math.max(Theme.gutter, (parent.width - width) / 2)
                    y: Theme.s6
                    width: Math.min(Theme.maxWidth, parent.width - 2 * Theme.gutter)
                    spacing: Theme.s4
                }
            }

            Footer {
                id: footer
                width: parent.width
            }
        }
    }

    Shortcut {
        sequence: StandardKey.MoveToNextPage
        onActivated: flick.scrollBy(flick.height * 0.85)
    }

    Shortcut {
        sequence: StandardKey.MoveToPreviousPage
        onActivated: flick.scrollBy(-flick.height * 0.85)
    }

    Connections {
        target: Nav

        function onPathChanged() {
            toTop.stop();
            flick.contentY = 0;
        }
    }

    // Back to top, once the reader is well down a long page.
    T.AbstractButton {
        id: topButton

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.gutter
        width: 52
        height: 52
        visible: opacity > 0
        opacity: flick.contentY > flick.height * 0.8 ? 1 : 0
        focusPolicy: Qt.NoFocus
        Accessible.role: Accessible.Button
        Accessible.name: "Back to top"
        onClicked: toTop.start()

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        background: Rectangle {
            radius: width / 2
            color: topButton.hovered || topButton.down ? Theme.primaryHover : Theme.primary

            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: -3
                radius: width / 2
                color: Theme.shadow
            }
        }

        contentItem: Text {
            text: "↑"
            color: Theme.primaryInk
            font.pixelSize: 22
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}
