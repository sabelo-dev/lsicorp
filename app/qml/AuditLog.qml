import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// Read-only record of who changed what, newest first.
ColumnLayout {
    id: root

    property var rows: []
    property string message: ""

    Layout.fillWidth: true
    spacing: Theme.s3

    Component.onCompleted: Supabase.select("audit_log", "select=*&order=at.desc&limit=100", function (error, data) {
        if (error)
            message = error.message;
        else
            rows = data;
    })

    /// "status: in-review -> available; reviewed_by: (empty) -> ..." for an update.
    function describe(entry) {
        if (entry.action !== "update" || !entry.old_data || !entry.new_data)
            return "";
        const show = v => v === null || v === "" ? "(empty)" : typeof v === "object" ? JSON.stringify(v) : String(v);
        const parts = [];
        for (const key in entry.new_data) {
            if (key === "updated_at" || JSON.stringify(entry.old_data[key]) === JSON.stringify(entry.new_data[key]))
                continue;
            const before = show(entry.old_data[key]);
            const after = show(entry.new_data[key]);
            parts.push(key + ": " + (before.length + after.length > 160 ? "changed" : before + " → " + after));
        }
        return parts.join("\n");
    }

    P {
        muted: true
        text: "The 100 most recent changes. Entries are written by the database and cannot be edited."
    }

    P {
        visible: root.message !== ""
        color: Theme.danger
        text: root.message
    }

    Repeater {
        model: root.rows

        Card {
            id: entry

            required property var modelData

            Layout.maximumWidth: Theme.measure
            padding: Theme.s3

            P {
                text: (entry.modelData.actor_name || "System") + " " + ({ insert: "created", update: "changed", delete: "deleted" })[entry.modelData.action]
                      + " " + entry.modelData.table_name + " “" + entry.modelData.record_key + "”"
            }

            P {
                small: true
                muted: true
                text: Rules.formatDate(entry.modelData.at) + ", " + String(entry.modelData.at).substring(11, 16) + " UTC"
            }

            P {
                visible: text !== ""
                small: true
                text: root.describe(entry.modelData)
            }
        }
    }
}
