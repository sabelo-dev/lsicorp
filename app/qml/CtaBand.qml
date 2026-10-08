import QtQuick
import QtQuick.Layouts
import LsiTools

// Navy call-to-action panel that closes a page by inviting an enquiry: the
// invitation on one side and its button on the other, stacked on a small screen.
Rectangle {
    id: band

    property string title: "Have a project in mind?"
    property string body: "Tell us what you are building or where things are getting stuck. We will come back to you."
    property string action: "Start a conversation"
    property string to: "/contact"

    readonly property int pad: Theme.narrow ? Theme.s5 : Theme.s6

    Layout.fillWidth: true
    Layout.topMargin: Theme.s6
    implicitHeight: row.implicitHeight + 2 * pad
    radius: Theme.radius
    color: Theme.heroTop
    border.width: Theme.dark ? 1 : 0
    border.color: Theme.border

    GridLayout {
        id: row
        x: band.pad
        y: band.pad
        width: parent.width - 2 * band.pad
        columns: Theme.narrow ? 1 : 2
        columnSpacing: Theme.s6
        rowSpacing: Theme.s4

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.s2

            Text {
                Layout.fillWidth: true
                text: band.title
                color: Theme.onHero
                font.pixelSize: Theme.narrow ? 22 : Theme.h2
                font.weight: Font.DemiBold
                font.letterSpacing: -0.4
                wrapMode: Text.Wrap
                Accessible.role: Accessible.Heading
                Accessible.name: text
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: 620
                text: band.body
                color: Theme.onHeroMuted
                font.pixelSize: Theme.body
                lineHeight: 1.5
                wrapMode: Text.Wrap
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }
        }

        AppButton {
            Layout.alignment: Qt.AlignVCenter
            text: band.action
            to: band.to
            onBrand: true
        }
    }
}
