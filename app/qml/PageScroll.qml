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
    /// How far down the page the reader is, from 0 to 1.
    readonly property real progress: flick.contentHeight > flick.height ? Math.min(1, flick.contentY / (flick.contentHeight - flick.height)) : 0

    /// Scrolls so that `item` (for example a section heading) is at the top.
    function scrollToItem(item) {
        const y = item.mapToItem(flick.contentItem, 0, 0).y - Theme.s4;
        jump.to = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), y));
        jump.duration = Theme.medium;
        jump.restart();
    }

    Binding {
        target: Theme
        property: "scrolled"
        value: flick.contentY > 6
    }

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

            // Always faintly visible on a page that scrolls, so there is something to
            // see and grab; stronger while the page is moving or the bar is in use.
            contentItem: Rectangle {
                implicitWidth: bar.hovered || bar.pressed ? 10 : 6
                radius: width / 2
                color: Theme.muted
                opacity: bar.pressed ? 0.9 : bar.hovered || bar.active || wheelIdle.running ? 0.65 : 0.3

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.fast
                    }
                }
            }
        }

        // Wheel and touchpad scrolling, handled here instead of by the Flickable.
        // The Flickable treats every wheel event as a flick with a velocity, which
        // suits the large steps of a mouse wheel but makes the stream of small
        // movements from a touchpad sluggish and uneven. Here the page moves by
        // exactly the distance reported: small movements at once, so it tracks the
        // fingers, and large steps (a wheel notch) eased over a moment.
        property real wheelTarget: 0

        function wheelBy(pixels) {
            const limit = Math.max(0, contentHeight - height);
            const from = wheelEase.running ? wheelTarget : contentY;
            wheelTarget = Math.max(0, Math.min(limit, from + pixels));
            toTop.stop();
            jump.stop();
            cancelFlick();
            if (Math.abs(pixels) < 40 || !Theme.motion) {
                wheelEase.stop();
                contentY = wheelTarget;
            } else {
                wheelEase.to = wheelTarget;
                wheelEase.restart();
            }
            wheelIdle.restart();
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            target: null
            onWheel: event => {
                // In a browser the amount arrives in pixels. On the desktop a wheel
                // reports notches (120 units each), taken here as 100 pixels.
                let pixels = event.pixelDelta.y;
                if (pixels === 0)
                    pixels = Platform.browser ? event.angleDelta.y : event.angleDelta.y / 120 * 100;
                // Shift + wheel, or a sideways swipe, is not vertical scrolling.
                if (pixels !== 0 && !(event.modifiers & Qt.ShiftModifier))
                    flick.wheelBy(-pixels);
                event.accepted = true;
            }
        }

        NumberAnimation {
            id: wheelEase
            target: flick
            property: "contentY"
            duration: 130
            easing.type: Easing.OutCubic
        }

        // Keeps the scrollbar prominent for a moment after the wheel stops.
        Timer {
            id: wheelIdle
            interval: 700
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
            duration: Theme.medium
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: jump
            target: flick
            property: "contentY"
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
            jump.stop();
            flick.contentY = 0;
        }
    }

    // Reading progress on long pages.
    Rectangle {
        width: parent.width * root.progress
        height: 3
        color: Theme.gold
        visible: flick.contentHeight > flick.height * 1.8
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
