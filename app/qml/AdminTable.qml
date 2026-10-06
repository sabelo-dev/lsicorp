import QtQuick
import QtQuick.Layouts
import LsiTools

// List and edit the records of one table. What can be edited is described by
// `entity` (see AdminPage); whether a save is accepted is decided by the database.
ColumnLayout {
    id: root

    /// { title, table, pk, order, fields, summary(row), badge(row), defaults, validate(values),
    ///   frozen(row), canCreate, canDelete(row), singleton }
    property var entity
    property var staffNames: ({})

    property var rows: []
    /// The record open in the form, or null when the list is showing.
    property var editing: null
    property bool isNew: false
    property bool busy: false
    property string message: ""
    property string notice: ""

    /// Each list and record has its own address: /admin/{key}, /admin/{key}/new, /admin/{key}/{id}.
    readonly property string base: "/admin/" + entity.key
    readonly property string routeId: Nav.segments.length > 2 ? Nav.segments[2] : ""

    readonly property bool frozen: editing !== null && !isNew && !!entity.frozen && entity.frozen(editing)
    readonly property var fields: editing === null ? [] : entity.fields.filter(f => isNew || !f.createOnly)
    /// Fields the form shows but never sends back (for example the text of an enquiry).
    function locked(field) {
        return !!field.locked;
    }

    Layout.fillWidth: true
    spacing: Theme.s4

    // The entity object is rebuilt whenever site content reloads; only a
    // different table means the list has to start again.
    readonly property string entityKey: entity.key
    Component.onCompleted: reload()
    onEntityKeyChanged: {
        rows = [];
        editing = null;
        notice = "";
        reload();
    }

    onRouteIdChanged: {
        message = "";
        sync();
    }

    /// Shows the list or the record that the address asks for.
    function sync() {
        if (routeId === "new" && entity.canCreate !== false) {
            create();
            return;
        }
        const wanted = entity.singleton ? rows[0] : rows.find(r => String(r[entity.pk[0]]) === routeId);
        if (wanted)
            open(wanted);
        else
            editing = null;
    }

    function reload() {
        busy = true;
        Supabase.select(entity.table, "select=*&order=" + entity.order, function (error, data) {
            busy = false;
            if (error) {
                message = error.message;
                return;
            }
            rows = data;
            sync();
        });
    }

    // Assigning null first rebuilds the form, so every input starts from the saved values.
    function open(row) {
        editing = null;
        isNew = false;
        editing = row;
    }

    function create() {
        editing = null;
        isNew = true;
        editing = Object.assign({}, entity.defaults || {});
    }

    function done(error, data, text) {
        busy = false;
        if (error) {
            message = error.message;
            return;
        }
        notice = text;
        Store.load();
        // The list is reloaded, then sync() reopens the saved record from fresh data.
        Nav.go(data && data.length > 0 ? base + "/" + encodeURIComponent(data[0][entity.pk[0]]) : base);
        reload();
    }

    function save() {
        message = "";
        notice = "";
        const values = {};
        const problems = [];
        for (let i = 0; i < form.count; i++) {
            const input = form.itemAt(i);
            const result = input.result();
            if (locked(input.field))
                continue;
            if (!result.ok)
                problems.push(result.message);
            else
                values[input.field.key] = result.value;
        }
        if (problems.length === 0 && entity.validate)
            Array.prototype.push.apply(problems, entity.validate(values));
        if (problems.length > 0) {
            message = problems.join("\n");
            return;
        }

        if (isNew) {
            busy = true;
            Supabase.insert(entity.table, values, (error, data) => done(error, data, "Created."));
            return;
        }
        const changes = {};
        for (const key in values) {
            if (JSON.stringify(values[key]) !== JSON.stringify(editing[key]))
                changes[key] = values[key];
        }
        if (Object.keys(changes).length === 0) {
            notice = "There are no changes to save.";
            return;
        }
        busy = true;
        Supabase.update(entity.table, Supabase.match(editing, entity.pk), changes, (error, data) => done(error, data, "Saved."));
    }

    function remove() {
        busy = true;
        message = "";
        Supabase.remove(entity.table, Supabase.match(editing, entity.pk), (error) => done(error, null, "Deleted."));
    }

    P {
        visible: root.notice !== ""
        text: root.notice
        Accessible.role: Accessible.AlertMessage
    }

    // List
    AppButton {
        visible: root.editing === null && root.entity.canCreate !== false
        text: "New " + root.entity.singular
        to: root.base + "/new"
    }

    P {
        visible: root.editing === null && root.message !== ""
        color: Theme.danger
        text: root.message
    }

    EmptyState {
        visible: root.editing === null && root.rows.length === 0 && !root.busy
        text: "There are no " + root.entity.title.toLowerCase() + " yet."
    }

    Repeater {
        model: root.editing === null ? root.rows.length : 0

        Card {
            id: item

            required property int index
            readonly property var row: root.rows[index]

            Layout.maximumWidth: Theme.measure
            padding: Theme.s3

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s3

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.s1

                    P {
                        text: root.entity.summary(item.row)
                    }

                    StatusBadge {
                        visible: !!root.entity.badge
                        tone: root.entity.badge ? root.entity.badge(item.row).tone : "neutral"
                        label: root.entity.badge ? root.entity.badge(item.row).label : ""
                    }
                }

                AppButton {
                    text: "Edit"
                    secondary: true
                    Accessible.name: "Edit " + root.entity.summary(item.row)
                    onClicked: {
                        root.notice = "";
                        Nav.go(root.base + "/" + encodeURIComponent(item.row[root.entity.pk[0]]));
                    }
                }
            }
        }
    }

    // Form
    H {
        level: 3
        visible: root.editing !== null
        text: root.isNew ? "New " + root.entity.singular : root.editing ? root.entity.summary(root.editing) : ""
    }

    Repeater {
        model: root.editing !== null && !root.isNew && root.entity.table === "releases" ? 1 : 0

        ReleaseWorkflow {
            release: root.editing
            staffNames: root.staffNames
            onChanged: release => root.done(null, [release], "Status changed.")
        }
    }

    P {
        visible: root.frozen
        muted: true
        text: "The details of a published release are frozen. To change them, use “Unpublish to edit”, save your changes, then have the release reviewed again."
    }

    Repeater {
        id: form
        model: root.fields.length

        FormField {
            required property int index

            field: root.fields[index]
            initial: root.editing ? root.editing[field.key] : null
            readOnly: root.frozen || root.locked(field)
        }
    }

    P {
        visible: root.editing !== null && root.message !== ""
        color: Theme.danger
        text: root.message
        Accessible.role: Accessible.AlertMessage
    }

    Flow {
        Layout.fillWidth: true
        visible: root.editing !== null
        spacing: Theme.s3

        AppButton {
            text: root.isNew ? "Create" : "Save changes"
            enabled: !root.busy && !root.frozen
            onClicked: root.save()
        }

        AppButton {
            visible: !root.entity.singleton
            text: "Back to list"
            secondary: true
            to: root.base
        }

        AppButton {
            visible: !root.isNew && !!root.entity.canDelete && root.editing !== null && root.entity.canDelete(root.editing)
            text: "Delete"
            secondary: true
            danger: true
            enabled: !root.busy
            onClicked: root.remove()
        }
    }
}
