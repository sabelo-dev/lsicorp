import QtQuick
import LsiTools

// Short text tile that stands in for a product icon: flat navy with a gold
// dot, after the logo. Decorative: the product name is always written next to it.
Rectangle {
    id: tile

    property string mark: ""
    property bool large: false

    implicitWidth: large ? 64 : 44
    implicitHeight: implicitWidth
    radius: Theme.radius
    color: Theme.heroTop
    border.width: Theme.dark ? 1 : 0
    border.color: Theme.border
    Accessible.ignored: true

    Text {
        anchors.centerIn: parent
        text: tile.mark
        color: Theme.onHero
        font.pixelSize: (tile.large ? 21 : 15) - (tile.mark.length > 2 ? (tile.large ? 4 : 3) : 0)
        font.weight: Font.Bold
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: tile.large ? 8 : 6
        width: tile.large ? 8 : 6
        height: width
        radius: width / 2
        color: Theme.gold
    }
}
