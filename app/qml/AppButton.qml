import QtQuick
import QtQuick.Templates as T
import LsiTools

// Primary or secondary action button, sized for touch, with a visible
// keyboard focus ring. `onBrand` restyles it for use on the navy hero band.
// While `busy` it keeps its place, its label and the keyboard focus, shows a
// spinner and does not navigate. A caller that handles clicked() itself should
// return early while busy, so that an action cannot be sent twice.
T.AbstractButton {
    id: control

    property string to: ""
    property bool secondary: false
    property bool danger: false
    property bool onBrand: false
    property bool busy: false

    /// Room taken by the spinner while busy.
    readonly property int busyWidth: busy ? 18 + Theme.s2 : 0

    readonly property color fill: onBrand ? (hovered || down ? "#f0c75a" : Theme.gold)
                                : danger ? Theme.danger
                                : hovered || down ? Theme.primaryHover : Theme.primary
    readonly property color fillInk: onBrand ? "#1c1503" : danger ? Theme.surface : Theme.primaryInk
    readonly property color outline: onBrand ? Theme.onHero : danger ? Theme.danger : Theme.primary

    implicitWidth: label.implicitWidth + busyWidth + leftPadding + rightPadding
    implicitHeight: Math.max(Theme.control, label.implicitHeight + topPadding + bottomPadding)
    leftPadding: Theme.s4
    rightPadding: Theme.s4
    topPadding: Theme.s2
    bottomPadding: Theme.s2
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.5
    scale: down && !busy ? 0.97 : 1
    Accessible.role: Accessible.Button
    Accessible.name: text + (busy ? ", in progress" : "")

    onClicked: if (to && !busy) Nav.go(to)
    onActiveFocusChanged: if (activeFocus) Theme.reveal(control)
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motion ? 80 : 0
        }
    }

    contentItem: Item {
        implicitWidth: label.implicitWidth + control.busyWidth
        implicitHeight: label.implicitHeight

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.s2

            Spinner {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.busy
                color: label.color
            }

            Text {
                id: label
                // Wraps inside the button when the label is longer than the space for it.
                width: Math.min(implicitWidth, Math.max(0, control.availableWidth - control.busyWidth))
                text: control.text
                color: control.secondary ? control.outline : control.fillInk
                font.pixelSize: Theme.label
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    background: Rectangle {
        radius: Theme.controlRadius
        color: !control.secondary ? control.fill
             : control.hovered || control.down ? (control.onBrand ? "#26ffffff" : Theme.primarySoft) : "transparent"
        border.width: control.secondary ? 1 : 0
        border.color: control.onBrand || control.danger ? control.outline : control.hovered ? Theme.primary : Theme.controlBorder

        Behavior on color {
            ColorAnimation {
                duration: Theme.fast
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: Theme.controlRadius + 3
            color: "transparent"
            border.width: 2
            border.color: control.onBrand ? Theme.onHero : Theme.focus
            visible: control.visualFocus
        }
    }

    HoverHandler {
        cursorShape: control.busy ? Qt.BusyCursor : Qt.PointingHandCursor
    }
}
