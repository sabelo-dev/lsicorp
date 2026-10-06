import QtQuick
import QtQuick.Layouts
import LsiTools

// Navy call-to-action panel that closes a page by inviting an enquiry.
Rectangle {
    id: band

    property string title: "Have a project in mind?"
    property string body: "Tell us what you are building or where things are getting stuck. We will come back to you."
    property string action: "Start a conversation"
    property string to: "/contact"

    Layout.fillWidth: true
    Layout.topMargin: Theme.s6
    implicitHeight: column.implicitHeight + 2 * (Theme.narrow ? Theme.s5 : Theme.s6)
    radius: Theme.radius
    clip: true

    gradient: Gradient {
        GradientStop {
            position: 0
            color: Theme.heroTop
        }

        GradientStop {
            position: 1
            color: Theme.heroBottom
        }
    }

    Rectangle {
        x: parent.width - width * 0.6
        y: -height * 0.45
        width: 260
        height: 260
        radius: 130
        color: Theme.gold
        opacity: 0.16
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.narrow ? Theme.s5 : Theme.s6
        spacing: Theme.s3

        Text {
            Layout.fillWidth: true
            text: band.title
            color: Theme.onHero
            font.pixelSize: Theme.narrow ? 24 : Theme.h2
            font.weight: Font.Bold
            font.letterSpacing: -0.5
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
            lineHeight: 1.45
            wrapMode: Text.Wrap
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        AppButton {
            Layout.topMargin: Theme.s2
            text: band.action
            to: band.to
            onBrand: true
        }
    }
}
