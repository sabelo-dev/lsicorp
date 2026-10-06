pragma Singleton
import QtQuick
import LsiTools
import "rules.mjs" as Rules

// The content the public pages show. Loaded from Supabase when a project is
// configured; otherwise from the preview data bundled with the app.
// Everything exposed here is already filtered to what the public may see,
// even when a signed-in staff member's session could read more.
QtObject {
    id: root

    /// "loading", "ready" or "error".
    property string state: "loading"
    property string errorText: ""
    /// "supabase" or "preview".
    property string source: ""

    property var site: ({ name: "LSI Corp", organisation: "Lifestyle Investment Corp", short_name: "LSI", description: "", tagline: "",
                          date_timezone: "UTC", contact_email: null, contact_phone: null, location: null,
                          support_email: null, support_url: null, allowed_external_domains: [] })
    property var services: []
    /// The portfolio: each product is a piece of work by LSI Corp.
    property var products: []
    property var releases: []
    property var docs: []
    property var faqs: []
    property var pages: []

    /// The signed-in person's staff record, or null. Drives what the admin area offers.
    property var staff: null
    readonly property string role: staff && staff.active ? staff.role : ""

    readonly property var queries: ({
        site_settings: "select=*",
        services: "select=*&order=sort_order",
        products: "select=*&order=sort_order",
        releases: "select=*&status=in.(available,superseded,withdrawn)",
        doc_pages: "select=*&status=eq.published&order=sort_order",
        faqs: "select=*&visible=is.true&order=sort_order",
        pages: "select=*"
    })

    Component.onCompleted: load()

    property Connections sessionWatch: Connections {
        target: Supabase
        function onSessionChanged() {
            root.loadStaff();
        }
    }

    function apply(data, from) {
        if (data.site_settings.length > 0)
            site = data.site_settings[0];
        services = data.services.slice().sort((a, b) => a.sort_order - b.sort_order);
        products = data.products.slice().sort((a, b) => a.sort_order - b.sort_order);
        releases = Rules.publicReleases(data.releases);
        docs = data.doc_pages.filter(d => d.status === "published").sort((a, b) => a.sort_order - b.sort_order);
        faqs = data.faqs.filter(f => f.visible).sort((a, b) => a.sort_order - b.sort_order);
        pages = data.pages;
        source = from;
        state = "ready";
    }

    function load() {
        if (!Supabase.configured) {
            apply(JSON.parse(Platform.seed()), "preview");
            return;
        }
        if (state !== "ready")
            state = "loading";
        const tables = Object.keys(queries);
        const data = {};
        let waiting = tables.length;
        let failed = false;
        tables.forEach(function (table) {
            Supabase.select(table, queries[table], function (error, rows) {
                if (failed)
                    return;
                if (error) {
                    failed = true;
                    errorText = error.message;
                    state = "error";
                    return;
                }
                data[table] = rows;
                if (--waiting === 0)
                    apply(data, "supabase");
            });
        });
        loadStaff();
    }

    function loadStaff() {
        if (!Supabase.signedIn) {
            staff = null;
            return;
        }
        Supabase.select("staff", "select=*&user_id=eq." + Supabase.userId, function (error, rows) {
            staff = !error && rows.length > 0 ? rows[0] : null;
        });
    }

    function service(slug) {
        return services.find(s => s.slug === slug) || null;
    }

    /// Portfolio items that demonstrate a service.
    function workFor(serviceSlug) {
        return products.filter(p => (p.services || []).indexOf(serviceSlug) >= 0);
    }

    /// Sends a contact enquiry. done(error).
    function sendEnquiry(enquiry, done) {
        if (!Supabase.configured) {
            done({ status: 0, message: "This copy of the site is not connected, so enquiries cannot be sent from it." });
            return;
        }
        Supabase.insertQuiet("enquiries", enquiry, done);
    }

    function product(slug) {
        return products.find(p => p.slug === slug) || null;
    }

    function releasesFor(slug) {
        return releases.filter(r => r.product_slug === slug);
    }

    function release(slug, platform, version) {
        return releases.find(r => r.product_slug === slug && r.platform === platform && r.version === version) || null;
    }

    function docsFor(slug) {
        return docs.filter(d => d.product_slug === slug);
    }

    function doc(slug, page) {
        return docs.find(d => d.product_slug === slug && d.slug === page) || null;
    }

    function faqsFor(slug) {
        return faqs.filter(f => f.product_slug === slug);
    }

    function page(slug) {
        return pages.find(p => p.slug === slug) || null;
    }

    function linkAllowed(link) {
        return Rules.checkExternalUrl(link, site.allowed_external_domains).length === 0;
    }
}
