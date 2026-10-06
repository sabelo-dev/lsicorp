import QtQuick
import QtQuick.Layouts
import LsiTools

// Responsive grid: as many equal columns as fit, down to one on a phone.
GridLayout {
    property int minColumnWidth: 300

    Layout.fillWidth: true
    columns: Math.max(1, Math.floor((width + columnSpacing) / (minColumnWidth + columnSpacing)))
    columnSpacing: Theme.s5
    rowSpacing: Theme.s5
}
