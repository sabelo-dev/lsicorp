import QtQuick
import LsiTools

// Status is always written out in words; the colour and dot only reinforce it.
Rectangle {
    id: badge

    property string tone: "neutral"
    property string label: ""
    property string prefix: ""

    implicitWidth: row.implicitWidth + 2 * Theme.s3
    implicitHeight: 28
    radius: height / 2
    color: Theme.tone(tone)[0]
    Accessible.role: Accessible.StaticText
    Accessible.name: (prefix ? prefix + ": " : "") + label

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: Theme.tone(badge.tone)[1]
        }

        Text {
            text: badge.label
            color: Theme.tone(badge.tone)[1]
            font.pixelSize: Theme.small
            font.weight: Font.DemiBold
        }
    }
}
