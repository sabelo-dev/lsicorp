import QtQuick
import LsiTools

// Short text tile that stands in for a product icon: navy with a gold dot,
// after the logo. Decorative: the product name is always written next to it.
Rectangle {
    id: tile

    property string mark: ""
    property bool large: false

    implicitWidth: large ? 76 : 52
    implicitHeight: implicitWidth
    radius: large ? 18 : 14
    Accessible.ignored: true

    gradient: Gradient {
        GradientStop {
            position: 0
            color: Theme.heroBottom
        }

        GradientStop {
            position: 1
            color: Theme.heroTop
        }
    }

    Text {
        anchors.centerIn: parent
        text: tile.mark
        color: Theme.onHero
        font.pixelSize: (tile.large ? 24 : 17) - (tile.mark.length > 2 ? (tile.large ? 5 : 4) : 0)
        font.weight: Font.Bold
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: tile.large ? 9 : 6
        width: tile.large ? 12 : 9
        height: width
        radius: width / 2
        color: Theme.gold
    }
}
