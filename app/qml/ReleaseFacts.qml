import QtQuick
import LsiTools
import "rules.mjs" as Rules

// Version, platform, date, compatibility and, for a direct file, its details and checksum.
Facts {
    property var release

    model: {
        const r = release;
        const web = r.destination_type === "web-app";
        const facts = [
            web ? { label: "Version", value: "Always the current version" }
                : { label: "Version", value: r.version + " (" + Rules.CHANNELS[r.channel] + ")" },
            { label: "Platform", value: Rules.PLATFORMS[r.platform] },
            { label: web ? "Listed here" : "Released", value: Rules.formatDate(r.release_date) + " (" + Store.site.date_timezone + ")" },
            { label: "Status", value: Rules.RELEASE_STATUSES[r.status] },
            { label: "Requires", value: r.compat_minimum },
            { label: "Devices", value: r.compat_device_class }
        ];
        if (r.compat_dependencies.length > 0)
            facts.push({ label: "Dependencies", value: r.compat_dependencies.join(", ") });
        if (r.destination_type === "file") {
            facts.push({ label: "File", value: r.artifact_filename + " (" + r.artifact_file_type + ", " + Rules.formatBytes(r.artifact_size_bytes) + ")" });
            facts.push({ label: "SHA-256", value: r.artifact_sha256, mono: true });
        }
        return facts;
    }
}
