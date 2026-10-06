import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// Staff area: sign in, then edit content and manage releases according to role.
// Hiding a tab here is a convenience only. Row-level security in the database
// is what actually stops a person from reading or changing a record.
PageScroll {
    id: page

    property bool busy: false
    property string message: ""
    property var staffNames: ({})

    readonly property bool staff: Supabase.signedIn && Store.role !== ""
    readonly property var productOptions: Store.products.map(p => ({ value: p.slug, text: p.public_name }))
    readonly property var allowed: Store.site.allowed_external_domains

    readonly property var everyone: ["editor", "release_manager", "admin"]
    readonly property var managers: ["release_manager", "admin"]

    readonly property var serviceOptions: Store.services.map(s => ({ value: s.slug, text: s.name }))

    readonly property var entities: [
        {
            key: "enquiries", title: "Enquiries", singular: "enquiry", table: "enquiries", pk: ["id"], order: "created_at.desc", roles: everyone,
            canCreate: false,
            summary: r => r.name + (r.organisation ? " (" + r.organisation + ")" : "") + ", " + Rules.formatDate(r.created_at),
            badge: r => ({ tone: r.status === "new" ? "coming-soon" : r.status === "closed" ? "neutral" : "in-development",
                           label: ({ "new": "New", "in-progress": "In progress", "closed": "Closed" })[r.status] }),
            canDelete: () => Store.role === "admin",
            fields: [
                { key: "name", label: "From", type: "text", locked: true },
                { key: "email", label: "Email", type: "text", locked: true },
                { key: "organisation", label: "Organisation", type: "text", nullable: true, locked: true },
                { key: "service_slug", label: "Asking about", type: "text", nullable: true, locked: true },
                { key: "message", label: "Message", type: "multiline", locked: true },
                { key: "status", label: "Status", type: "select", options: [{ value: "new", text: "New" }, { value: "in-progress", text: "In progress" }, { value: "closed", text: "Closed" }] },
                { key: "notes", label: "Internal notes", type: "multiline", nullable: true, hint: "Visible to staff only." }
            ]
        },
        {
            key: "services", title: "Services", singular: "service", table: "services", pk: ["slug"], order: "sort_order", roles: everyone,
            summary: r => r.name,
            canDelete: () => Store.role === "admin",
            defaults: { sort_order: 10, offerings: [] },
            fields: [
                { key: "slug", label: "Address name", type: "text", createOnly: true, hint: "Lowercase letters, digits and hyphens. Cannot be changed later." },
                { key: "name", label: "Name", type: "text" },
                { key: "mark", label: "Tile text", type: "text", hint: "Up to 4 characters." },
                { key: "tagline", label: "Tagline", type: "text" },
                { key: "summary", label: "Summary", type: "multiline" },
                { key: "offerings", label: "What it includes", type: "list" },
                { key: "sort_order", label: "Position in lists", type: "number" }
            ]
        },
        {
            key: "releases", title: "Releases", singular: "release", table: "releases", pk: ["id"], order: "release_date.desc", roles: managers,
            summary: r => (Store.product(r.product_slug) ? Store.product(r.product_slug).public_name : r.product_slug)
                          + " " + r.version + " for " + Rules.PLATFORMS[r.platform],
            badge: r => ({ tone: r.status, label: Rules.RELEASE_STATUSES[r.status] }),
            frozen: r => r.status !== "draft" && r.status !== "in-review",
            canDelete: r => r.status === "draft" && Store.role === "admin",
            validate: values => Rules.checkRelease(values, allowed),
            defaults: { channel: "stable", platform: "android", destination_type: "store", compat_dependencies: [], steps: [], notes: [], known_issues: [] },
            fields: [
                { key: "product_slug", label: "Product", type: "select", options: productOptions },
                { key: "platform", label: "Platform", type: "select", options: Rules.options(Rules.PLATFORMS) },
                { key: "version", label: "Version", type: "text", hint: "For example 1.2.0. Letters, digits, dots and hyphens." },
                { key: "channel", label: "Channel", type: "select", options: Rules.options(Rules.CHANNELS) },
                { key: "release_date", label: "Release date", type: "text", hint: "YYYY-MM-DD, in " + Store.site.date_timezone + "." },
                { key: "destination_type", label: "Destination type", type: "select", options: Rules.options(Rules.DESTINATION_TYPES) },
                { key: "destination_url", label: "Destination URL", type: "text", hint: "https only, on an allowed domain: " + (allowed.join(", ") || "none configured") + "." },
                { key: "artifact_filename", label: "File name", type: "text", nullable: true, hint: "Direct file downloads only." },
                { key: "artifact_file_type", label: "File type", type: "text", nullable: true, hint: "For example: Windows installer." },
                { key: "artifact_size_bytes", label: "File size in bytes", type: "number", nullable: true },
                { key: "artifact_sha256", label: "SHA-256 checksum", type: "text", nullable: true, hint: "64 lowercase hex characters, computed from the file that is actually served." },
                { key: "compat_minimum", label: "Minimum OS or runtime", type: "text" },
                { key: "compat_device_class", label: "Supported devices", type: "text" },
                { key: "compat_dependencies", label: "Required dependencies", type: "list" },
                { key: "steps", label: "Install or launch steps", type: "list" },
                { key: "notes", label: "Release notes", type: "list" },
                { key: "known_issues", label: "Known issues", type: "list" },
                { key: "licence", label: "Licence", type: "text" },
                { key: "support_route", label: "Support route", type: "text" }
            ]
        },
        {
            key: "work", title: "Work", singular: "portfolio item", table: "products", pk: ["slug"], order: "sort_order", roles: everyone,
            summary: r => r.public_name,
            badge: r => ({ tone: r.status, label: Rules.PRODUCT_STATUSES[r.status] }),
            canDelete: () => Store.role === "admin",
            validate: values => [values.support_url, values.privacy_url].filter(l => !!l)
                                    .reduce((found, link) => found.concat(Rules.checkProductLink(link, allowed)), []),
            defaults: { status: "in-development", sort_order: 10, platforms: [], limitations: [], audiences: [], capabilities: [], requirements: [] },
            fields: [
                { key: "slug", label: "Address name", type: "text", createOnly: true, hint: "Lowercase letters, digits and hyphens. Used in the page address and cannot be changed later." },
                { key: "public_name", label: "Public name", type: "text" },
                { key: "internal_name", label: "Internal name", type: "text", hint: "Shown as “Also known as” when it differs from the public name." },
                { key: "mark", label: "Tile text", type: "text", hint: "Up to 4 characters." },
                { key: "tagline", label: "Tagline", type: "text" },
                { key: "summary", label: "Summary", type: "multiline" },
                { key: "category", label: "Category", type: "text" },
                { key: "sort_order", label: "Position in lists", type: "number" },
                { key: "status", label: "Status", type: "select", options: Rules.options(Rules.PRODUCT_STATUSES) },
                { key: "status_note", label: "Status note", type: "multiline", hint: "One or two sentences shown next to the status." },
                { key: "services", label: "Services demonstrated", type: "list", hint: "One service address name per line: " + (serviceOptions.map(o => o.value).join(", ") || "none yet") + "." },
                { key: "platforms", label: "Target platforms", type: "list", hint: "One per line: android, ios, web, windows, macos, linux or other." },
                { key: "platform_note", label: "Platform differences", type: "multiline", nullable: true },
                { key: "getting_started", label: "Getting started", type: "multiline" },
                { key: "limitations", label: "Known limitations", type: "list" },
                { key: "audiences", label: "Audiences", type: "json", hint: "A list of { \"name\", \"description\" }." },
                { key: "capabilities", label: "Capabilities", type: "json", hint: "A list of { \"name\", \"description\", \"availability\": \"available\" or \"planned\", optional \"group\" and \"platformNote\" }." },
                { key: "requirements", label: "Requirements", type: "json", hint: "A list of { \"label\", \"detail\" }." },
                { key: "notice_title", label: "Notice title", type: "text", nullable: true, hint: "For a caution shown in the overview. Fill in both notice fields or neither." },
                { key: "notice_body", label: "Notice text", type: "multiline", nullable: true },
                { key: "support_url", label: "Support link", type: "text", nullable: true, hint: "A site path such as /support, or an https URL on an allowed domain. Leave empty for the default." },
                { key: "privacy_url", label: "Privacy link", type: "text", nullable: true }
            ]
        },
        {
            key: "documentation", title: "Documentation", singular: "documentation page", table: "doc_pages", pk: ["id"], order: "product_slug,sort_order", roles: everyone,
            summary: r => r.product_slug + ": " + r.title,
            badge: r => ({ tone: r.status === "published" ? "available" : "neutral", label: r.status === "published" ? "Published" : "Draft" }),
            canDelete: () => Store.role === "admin",
            validate: values => Rules.checkMarkdown(values.body, allowed),
            defaults: { status: "draft", sort_order: 10, last_reviewed: new Date().toISOString().substring(0, 10) },
            fields: [
                { key: "product_slug", label: "Product", type: "select", options: productOptions },
                { key: "slug", label: "Address name", type: "text", hint: "Lowercase letters, digits and hyphens." },
                { key: "title", label: "Title", type: "text" },
                { key: "summary", label: "Summary", type: "text" },
                { key: "audience", label: "Audience", type: "text", hint: "For example: Users, Administrators, Creators." },
                { key: "sort_order", label: "Position in the product’s list", type: "number" },
                { key: "status", label: "Status", type: "select", options: [{ value: "draft", text: "Draft (staff only)" }, { value: "published", text: "Published" }] },
                { key: "last_reviewed", label: "Last reviewed", type: "text", hint: "YYYY-MM-DD." },
                { key: "body", label: "Content", type: "multiline", hint: "Markdown. Links must be site paths such as /downloads or https URLs on an allowed domain. HTML is not allowed." }
            ]
        },
        {
            key: "faqs", title: "FAQs", singular: "question", table: "faqs", pk: ["id"], order: "product_slug,sort_order", roles: everyone,
            summary: r => r.product_slug + ": " + r.question,
            badge: r => ({ tone: r.visible ? "available" : "neutral", label: r.visible ? "Visible" : "Hidden" }),
            canDelete: () => Store.role === "admin",
            defaults: { visible: false, sort_order: 10 },
            fields: [
                { key: "product_slug", label: "Product", type: "select", options: productOptions },
                { key: "question", label: "Question", type: "text" },
                { key: "answer", label: "Answer", type: "multiline" },
                { key: "category", label: "Category", type: "text" },
                { key: "escalation", label: "If the answer does not help", type: "text", nullable: true },
                { key: "visible", label: "Visible to the public", type: "bool" },
                { key: "sort_order", label: "Position in the list", type: "number" }
            ]
        },
        {
            key: "pages", title: "Pages", singular: "page", table: "pages", pk: ["slug"], order: "slug", roles: everyone,
            summary: r => r.title,
            canDelete: () => Store.role === "admin",
            validate: values => Rules.checkMarkdown(values.body, allowed),
            defaults: { last_reviewed: new Date().toISOString().substring(0, 10) },
            fields: [
                { key: "slug", label: "Address name", type: "text", createOnly: true, hint: "about, privacy, terms and accessibility are linked from the site." },
                { key: "title", label: "Title", type: "text" },
                { key: "description", label: "Description", type: "text" },
                { key: "last_reviewed", label: "Last reviewed", type: "text", hint: "YYYY-MM-DD." },
                { key: "body", label: "Content", type: "multiline", hint: "Markdown. HTML is not allowed." }
            ]
        },
        { key: "audit-log", title: "Audit log", audit: true, roles: everyone },
        {
            key: "settings", title: "Site settings", singular: "settings", table: "site_settings", pk: ["id"], order: "id", roles: ["admin"],
            singleton: true, canCreate: false,
            summary: r => "Site settings",
            fields: [
                { key: "name", label: "Site name", type: "text" },
                { key: "organisation", label: "Organisation", type: "text" },
                { key: "short_name", label: "Short name", type: "text" },
                { key: "tagline", label: "Tagline", type: "text", hint: "The one-line statement of what the company does." },
                { key: "description", label: "Description", type: "multiline" },
                { key: "contact_email", label: "Contact email", type: "text", nullable: true, hint: "Shown on the Contact page." },
                { key: "contact_phone", label: "Contact phone", type: "text", nullable: true },
                { key: "location", label: "Location", type: "text", nullable: true },
                { key: "date_timezone", label: "Timezone label for release dates", type: "text" },
                { key: "support_email", label: "Support email", type: "text", nullable: true },
                { key: "support_url", label: "Support page", type: "text", nullable: true, hint: "An https URL on an allowed domain." },
                { key: "allowed_external_domains", label: "Allowed external domains", type: "list", hint: "One hostname per line, for example play.google.com. Download, launch and content links may only point to these." }
            ]
        },
        {
            key: "staff", title: "Staff", singular: "staff member", table: "staff", pk: ["user_id"], order: "display_name", roles: ["admin"],
            summary: r => r.display_name + " (" + Rules.STAFF_ROLES[r.role] + ")",
            badge: r => ({ tone: r.active ? "available" : "neutral", label: r.active ? "Active" : "Deactivated" }),
            defaults: { role: "editor", active: true },
            fields: [
                { key: "user_id", label: "User ID", type: "text", createOnly: true, hint: "The UUID of the person’s account, from Authentication > Users in the Supabase dashboard." },
                { key: "display_name", label: "Name", type: "text" },
                { key: "role", label: "Role", type: "select", options: Rules.options(Rules.STAFF_ROLES) },
                { key: "active", label: "Active", type: "bool" }
            ]
        }
    ]

    readonly property var tabs: entities.filter(e => e.roles.indexOf(Store.role) >= 0)
    /// The tab named in the address (/admin/{key}), or the first one this role may use.
    readonly property int tab: Math.max(0, tabs.findIndex(e => e.key === Nav.segments[1]))
    readonly property var current: tabs.length > 0 ? tabs[tab] : null

    onStaffChanged: if (staff) loadNames()
    Component.onCompleted: if (staff) loadNames()

    function loadNames() {
        Supabase.select("staff", "select=user_id,display_name", function (error, rows) {
            if (error)
                return;
            const names = {};
            rows.forEach(r => names[r.user_id] = r.display_name);
            staffNames = names;
        });
    }

    function signIn() {
        message = "";
        if (email.text.trim() === "" || password.text === "") {
            message = "Enter your email address and password.";
            return;
        }
        busy = true;
        Supabase.signIn(email.text.trim(), password.text, function (error) {
            busy = false;
            password.text = "";
            if (error)
                message = error.status === 400 ? "The email address or password is not correct." : error.message;
        });
    }

    Breadcrumbs {
        items: [{ label: "Staff" }]
    }

    H {
        level: 1
        text: "Staff"
    }

    // Not connected
    EmptyState {
        visible: !Supabase.configured
        text: "Staff sign-in is unavailable because this copy of the site is not connected to its content service. Set the Supabase project URL and anon key in config.js."
    }

    // Sign in
    ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: 420
        visible: Supabase.configured && !Supabase.signedIn
        spacing: Theme.s4

        P {
            text: "Sign in with your " + Store.site.short_name + " staff account to edit content and manage releases."
        }

        FieldLabel {
            text: "Email address"

            Input {
                id: email
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
                Accessible.name: "Email address"
                onAccepted: password.forceActiveFocus()
            }
        }

        FieldLabel {
            text: "Password"

            Input {
                id: password
                echoMode: TextInput.Password
                Accessible.name: "Password"
                onAccepted: page.signIn()
            }
        }

        P {
            visible: page.message !== ""
            color: Theme.danger
            text: page.message
            Accessible.role: Accessible.AlertMessage
        }

        AppButton {
            text: page.busy ? "Signing in…" : "Sign in"
            enabled: !page.busy
            onClicked: page.signIn()
        }
    }

    // Signed in
    Flow {
        Layout.fillWidth: true
        visible: Supabase.signedIn
        spacing: Theme.s4

        P {
            Layout.fillWidth: false
            topPadding: 10
            text: "Signed in as " + (Store.staff ? Store.staff.display_name : Supabase.userEmail)
                  + (Store.role ? " (" + Rules.STAFF_ROLES[Store.role] + ")" : "")
        }

        AppButton {
            text: "Sign out"
            secondary: true
            onClicked: Supabase.signOut()
        }
    }

    EmptyState {
        visible: Supabase.signedIn && Store.role === ""
        text: "This account is not an active member of staff, so there is nothing to manage. Ask an administrator to add you."
    }

    Flow {
        Layout.fillWidth: true
        Layout.topMargin: Theme.s3
        visible: page.staff
        spacing: Theme.s2
        Accessible.role: Accessible.PageTabList

        Repeater {
            model: page.tabs.length

            AppButton {
                required property int index

                text: page.tabs[index].title
                secondary: index !== page.tab
                Accessible.role: Accessible.PageTab
                Accessible.name: text + (index === page.tab ? ", selected" : "")
                to: "/admin/" + page.tabs[index].key
            }
        }
    }

    H {
        visible: page.staff && page.current !== null
        text: page.current ? page.current.title : ""
    }

    Repeater {
        model: page.staff && page.current && !page.current.audit ? 1 : 0

        AdminTable {
            entity: page.current
            staffNames: page.staffNames
        }
    }

    Repeater {
        model: page.staff && page.current && page.current.audit ? 1 : 0

        AuditLog {}
    }
}
