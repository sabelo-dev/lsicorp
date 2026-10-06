import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// Draft, review, publish, supersede and withdraw. The buttons offered follow
// the signed-in person's role; the database enforces the same rules.
Card {
    id: root

    property var release
    /// user id -> display name
    property var staffNames: ({})
    property bool busy: false
    property string message: ""

    signal changed(var release)

    readonly property var steps: Rules.releaseSteps(release, Store.role, Supabase.userId)

    function name(id) {
        return id ? (staffNames[id] || "a staff member") : "nobody yet";
    }

    function move(step) {
        const changes = { status: step.to, superseded_by: null, withdrawn_reason: null };
        if (step.needs) {
            const typed = extra.text.trim();
            if (typed === "") {
                message = step.needs === "withdrawn_reason" ? "Give the reason for withdrawing this release."
                                                            : "Enter the version that replaced this release.";
                return;
            }
            changes[step.needs] = typed;
        }
        busy = true;
        message = "";
        Supabase.update("releases", "id=eq." + release.id, changes, function (error, rows) {
            busy = false;
            if (error)
                message = error.message;
            else
                root.changed(rows[0]);
        });
    }

    Layout.maximumWidth: Theme.measure

    Flow {
        Layout.fillWidth: true
        spacing: Theme.s3

        H {
            level: 3
            Layout.topMargin: 0
            text: "Release status"
        }

        StatusBadge {
            tone: root.release.status
            label: Rules.RELEASE_STATUSES[root.release.status]
        }
    }

    P {
        small: true
        text: "Prepared by " + root.name(root.release.prepared_by) + ". "
              + (root.release.reviewed_by ? "Approved by " + root.name(root.release.reviewed_by) + " on " + Rules.formatDate(root.release.reviewed_at) + "."
                                          : "Not approved yet.")
    }

    P {
        small: true
        muted: true
        visible: root.release.status === "in-review" && root.release.prepared_by === Supabase.userId
        text: "You prepared this release, so a different release manager must approve it."
    }

    P {
        small: true
        muted: true
        visible: root.release.status === "draft" || root.release.status === "in-review"
        text: "Save any changes to the details below before using these buttons."
    }

    FieldLabel {
        visible: root.steps.some(s => !!s.needs)
        text: root.release.status === "available" ? "Reason (to withdraw) or replacing version (to supersede)" : "Reason for withdrawing"

        Input {
            id: extra
            Accessible.name: parent.text
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Theme.s3

        Repeater {
            model: root.steps.length

            AppButton {
                required property int index
                readonly property var step: root.steps[index]

                text: step.label
                secondary: step.to !== "available"
                danger: step.to === "withdrawn"
                enabled: !root.busy
                onClicked: root.move(step)
            }
        }
    }

    P {
        visible: root.steps.length === 0
        small: true
        muted: true
        text: "Your role cannot change the status of a release."
    }

    P {
        visible: root.message !== ""
        color: Theme.danger
        text: root.message
        Accessible.role: Accessible.AlertMessage
    }
}
