import QtQuick
import QtQuick.Templates as T
import LsiTools

// Primary or secondary action button, sized for touch, with a visible
// keyboard focus ring. `onBrand` restyles it for use on the navy hero band.
T.AbstractButton {
    id: control

    property string to: ""
    property bool secondary: false
    property bool danger: false
    property bool onBrand: false

    readonly property color fill: onBrand ? (hovered || down ? "#f0c75a" : Theme.gold)
                                : danger ? Theme.danger
                                : hovered || down ? Theme.primaryHover : Theme.primary
    readonly property color fillInk: onBrand ? "#1c1503" : danger ? Theme.surface : Theme.primaryInk
    readonly property color outline: onBrand ? Theme.onHero : danger ? Theme.danger : Theme.primary

    implicitWidth: label.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(Theme.touch, label.implicitHeight + topPadding + bottomPadding)
    leftPadding: 20
    rightPadding: 20
    topPadding: Theme.s2
    bottomPadding: Theme.s2
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.5
    scale: down ? 0.97 : 1
    Accessible.role: Accessible.Button
    Accessible.name: text

    onClicked: if (to) Nav.go(to)
    onActiveFocusChanged: if (activeFocus) Theme.reveal(control)
    Keys.onReturnPressed: click()
    Keys.onEnterPressed: click()

    Behavior on scale {
        NumberAnimation {
            duration: 80
        }
    }

    contentItem: Text {
        id: label
        text: control.text
        color: control.secondary ? control.outline : control.fillInk
        font.pixelSize: Theme.body
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }

    background: Rectangle {
        radius: Theme.controlRadius
        color: !control.secondary ? control.fill
             : control.hovered || control.down ? (control.onBrand ? "#26ffffff" : Theme.primarySoft) : "transparent"
        border.width: control.secondary ? 2 : 0
        border.color: control.outline

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: Theme.controlRadius + 4
            color: "transparent"
            border.width: 3
            border.color: control.onBrand ? Theme.onHero : Theme.focus
            visible: control.visualFocus
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
