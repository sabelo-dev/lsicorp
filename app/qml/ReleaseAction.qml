import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// The only place a download or launch control is created. It shows a button
// for an available release whose destination is on the allowlist, and a plain
// statement with a way forward in every other case. The button says what it
// will fetch, confirms that it started, and cannot start the same download
// twice by accident.
ColumnLayout {
    id: root

    property var release
    property string productName: ""

    readonly property bool live: release.status === "available" && Store.linkAllowed(release.destination_url)
    readonly property bool file: release.destination_type === "file"
    /// True for a moment after the button is used.
    property bool started: false

    Layout.fillWidth: true
    spacing: Theme.s2

    function start() {
        if (starting.running)
            return;
        starting.restart();
        started = true;
        root.Accessible.announce(root.file ? "Download started" : "Opening " + Rules.hostOf(root.release.destination_url));
        Nav.follow(root.release.destination_url);
    }

    // A second press within this time is ignored, so one file is not fetched twice.
    Timer {
        id: starting
        interval: 4000
    }

    AppButton {
        visible: root.live
        busy: starting.running
        text: Rules.actionLabel(root.release, root.productName)
        Accessible.name: text + ", version " + root.release.version + ", " + Rules.CHANNELS[root.release.channel] + " channel"
                         + (root.file ? ", " + root.release.artifact_file_type + ", " + Rules.formatBytes(root.release.artifact_size_bytes) : "")
                         + (busy ? ", in progress" : "")
        onClicked: root.start()
    }

    P {
        visible: root.live
        small: true
        muted: true
        // A web app is always the current version, so no version number is quoted for it.
        text: (root.release.destination_type === "web-app" ? "Runs in your browser. "
               : "Version " + root.release.version + " (" + Rules.CHANNELS[root.release.channel] + ") for " + Rules.PLATFORMS[root.release.platform] + ". ")
              + (root.file ? root.release.artifact_filename + ", " + root.release.artifact_file_type + ", "
                             + Rules.formatBytes(root.release.artifact_size_bytes) + ". " : "")
              + Rules.DESTINATION_TYPES[root.release.destination_type]
              + ": this link leaves the LSI website and opens " + Rules.hostOf(root.release.destination_url) + "."
    }

    P {
        visible: root.live && root.started && root.file
        small: true
        text: "Download started. Your browser saves the file or asks where to put it. If nothing happens, try the button again or use the support link on this page."
    }

    EmptyState {
        visible: !root.live
        text: root.release.status === "withdrawn" ? "This release has been withdrawn and is no longer offered."
            : root.release.status === "superseded" ? "This release has been replaced by a newer version and is no longer offered."
            : "This release cannot be offered at the moment, because its download link could not be confirmed. Nothing is wrong with your device."
    }

    Flow {
        Layout.fillWidth: true
        visible: !root.live
        spacing: Theme.s3

        LinkText {
            text: "See all releases of " + root.productName
            to: "/work/" + root.release.product_slug
            font.pixelSize: Theme.small
        }

        LinkText {
            text: "Get support"
            to: "/support"
            font.pixelSize: Theme.small
        }
    }
}
