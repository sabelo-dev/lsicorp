import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// The only place a download or launch control is created. It shows a button
// for an available release whose destination is on the allowlist, and a plain
// statement in every other case.
ColumnLayout {
    id: root

    property var release
    property string productName: ""

    readonly property bool live: release.status === "available" && Store.linkAllowed(release.destination_url)

    Layout.fillWidth: true
    spacing: Theme.s2

    AppButton {
        visible: root.live
        text: Rules.actionLabel(root.release, root.productName)
        Accessible.name: text + ", version " + root.release.version + ", " + Rules.CHANNELS[root.release.channel] + " channel"
        onClicked: Nav.follow(root.release.destination_url)
    }

    P {
        visible: root.live
        small: true
        muted: true
        // A web app is always the current version, so no version number is quoted for it.
        text: (root.release.destination_type === "web-app" ? "Runs in your browser. "
               : "Version " + root.release.version + " (" + Rules.CHANNELS[root.release.channel] + ") for " + Rules.PLATFORMS[root.release.platform] + ". ")
              + Rules.DESTINATION_TYPES[root.release.destination_type]
              + ": this link leaves the LSI website and opens " + Rules.hostOf(root.release.destination_url) + "."
    }

    EmptyState {
        visible: !root.live
        text: root.release.status === "withdrawn" ? "This release has been withdrawn and is no longer offered."
            : root.release.status === "superseded" ? "This release has been replaced by a newer version and is no longer offered."
            : "This release is not available at the moment."
    }
}
