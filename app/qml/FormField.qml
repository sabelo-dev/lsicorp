import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools

// One labelled input in an admin form, chosen by field.type:
// "text", "number", "multiline", "list" (one item per line), "json", "select" or "bool".
// The form reads the value back with result() when it is saved.
FieldLabel {
    id: root

    /// { key, label, type, options, nullable, hint }
    property var field
    property var initial
    property bool readOnly: false

    readonly property bool isArea: field.type === "multiline" || field.type === "list" || field.type === "json"
    readonly property bool isLine: field.type === "text" || field.type === "number"

    text: field.label + (field.nullable || field.type === "bool" || field.type === "list" ? "" : " (required)")
    hint: field.hint || (field.type === "list" ? "One item per line." : "")
    Layout.maximumWidth: Theme.measure

    function toText(value) {
        if (value === null || value === undefined)
            return "";
        if (field.type === "list")
            return value.join("\n");
        if (field.type === "json")
            return JSON.stringify(value, null, 2);
        return String(value);
    }

    /// { ok, value } or { ok: false, message }.
    function result() {
        const fail = message => ({ ok: false, message: field.label + " " + message });
        switch (field.type) {
        case "bool":
            return { ok: true, value: toggle.checked };
        case "select":
            return { ok: true, value: choice.currentValue };
        case "list":
            return { ok: true, value: area.text.split("\n").map(s => s.trim()).filter(s => s.length > 0) };
        case "json":
            try {
                return { ok: true, value: JSON.parse(area.text) };
            } catch (e) {
                return fail("is not valid JSON.");
            }
        }
        const typed = (root.isArea ? area.text : line.text).trim();
        if (typed === "")
            return field.nullable ? { ok: true, value: null } : fail("is required.");
        if (field.type === "number")
            return isNaN(Number(typed)) ? fail("must be a number.") : { ok: true, value: Number(typed) };
        return { ok: true, value: typed };
    }

    Input {
        id: line
        visible: root.isLine
        text: root.isLine ? root.toText(root.initial) : ""
        readOnly: root.readOnly
        Accessible.name: root.field.label
    }

    TextArea {
        id: area
        Layout.fillWidth: true
        Layout.minimumHeight: 120
        padding: Theme.s3
        color: Theme.ink
        selectByMouse: true
        visible: root.isArea
        text: root.isArea ? root.toText(root.initial) : ""
        readOnly: root.readOnly
        wrapMode: TextArea.Wrap
        font.pixelSize: root.field.type === "json" ? Theme.small : Theme.body
        font.family: root.field.type === "json" ? "monospace" : Qt.application.font.family
        Accessible.name: root.field.label
        onActiveFocusChanged: if (activeFocus) Theme.reveal(area)

        background: Rectangle {
            color: area.readOnly ? Theme.surfaceAlt : Theme.surface
            border.color: area.activeFocus ? Theme.focus : Theme.muted
            border.width: area.activeFocus ? 2 : 1
            radius: Theme.controlRadius
        }
    }

    Select {
        id: choice
        visible: root.field.type === "select"
        enabled: !root.readOnly
        model: root.field.options || []
        currentIndex: Math.max(0, (root.field.options || []).findIndex(o => o.value === root.initial))
        Accessible.name: root.field.label
    }

    CheckBox {
        id: toggle
        visible: root.field.type === "bool"
        enabled: !root.readOnly
        checked: root.initial === true
        text: "Yes"
        font.pixelSize: Theme.body
        Accessible.name: root.field.label
    }
}
