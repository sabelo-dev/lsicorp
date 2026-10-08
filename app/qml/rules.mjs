// Display vocabulary and publishing rules shared by the app (imported from
// QML) and the Node tooling and tests. Plain functions over database rows, and
// only language features the QML engine supports. The database enforces the
// same rules (supabase/migrations); these exist so people see a clear message
// before a save is refused.

export const PLATFORMS = {
    android: "Android", ios: "iOS", web: "Web", windows: "Windows", macos: "macOS", linux: "Linux", other: "Other"
};

export const PRODUCT_STATUSES = {
    "available": "Available", "in-development": "In Development", "coming-soon": "Coming Soon", "maintenance": "Maintenance"
};

export const RELEASE_STATUSES = {
    "draft": "Draft", "in-review": "In review", "available": "Available", "superseded": "Superseded", "withdrawn": "Withdrawn"
};

export const CHANNELS = { stable: "Stable", beta: "Beta", preview: "Preview" };

export const DESTINATION_TYPES = {
    "store": "Official app store listing", "web-app": "Web application", "file": "Direct file download"
};

export const STAFF_ROLES = { editor: "Content editor", release_manager: "Release manager", admin: "Administrator" };

const SECRET_PARAM = /token|secret|signature|key|password|credential|x-amz|x-goog|expires|^sig$/i;
const HTTPS_URL = /^https:\/\/([^\/?#@:\s]+)(?::\d+)?(?:[\/?#]|$)/;

/** The host of an https URL, or "" if it is not one. */
export function hostOf(url) {
    const match = HTTPS_URL.exec(url || "");
    return match ? match[1].toLowerCase() : "";
}

/** Problems with a link that leaves the LSI website. Empty means it may be published. */
export function checkExternalUrl(raw, allowedDomains) {
    const host = hostOf(raw);
    if (!host)
        return ['"' + raw + '" must be an https URL without embedded credentials'];
    const problems = [];
    if (allowedDomains.indexOf(host) < 0)
        problems.push('host "' + host + '" is not in the allowed external domains');
    const query = raw.split("#")[0].split("?")[1] || "";
    const pairs = query.split("&");
    for (let i = 0; i < pairs.length; i++) {
        const name = pairs[i].split("=")[0];
        if (name && SECRET_PARAM.test(name))
            problems.push('query parameter "' + name + '" looks like a credential or a signed private URL');
    }
    return problems;
}

const isSitePath = (link) => link.charAt(0) === "/" && link.charAt(1) !== "/";

/** A product-level link is a path on this site or an allowlisted https URL. */
export function checkProductLink(raw, allowedDomains) {
    return isSitePath(raw) ? [] : checkExternalUrl(raw, allowedDomains);
}

/** Raw HTML and unapproved links are not allowed in Markdown content. */
export function checkMarkdown(source, allowedDomains) {
    const problems = [];
    const prose = source.replace(/```[\s\S]*?```/g, "").replace(/`[^`\n]*`/g, "");
    const targets = [];
    let match;

    const autolink = /<((?:https?|mailto|javascript):[^>\s]+)>/gi;
    while ((match = autolink.exec(prose)) !== null)
        targets.push(match[1]);
    const tag = /<\/?[a-zA-Z][^>]*>/.exec(prose.replace(autolink, ""));
    if (tag)
        problems.push("raw HTML is not allowed (found " + tag[0] + ")");

    const inline = /\]\(\s*<?([^)\s>]+)/g;
    while ((match = inline.exec(prose)) !== null)
        targets.push(match[1]);
    const reference = /^\[[^\]]+\]:\s*<?(\S+?)>?\s*$/gm;
    while ((match = reference.exec(prose)) !== null)
        targets.push(match[1]);

    for (let i = 0; i < targets.length; i++) {
        const target = targets[i];
        if (target.charAt(0) === "#" || isSitePath(target) || /^mailto:/i.test(target))
            continue;
        if (!/^https?:/i.test(target)) {
            problems.push('link "' + target + '" must be a site path starting with "/" or an approved https URL');
            continue;
        }
        const found = checkExternalUrl(target, allowedDomains);
        for (let j = 0; j < found.length; j++)
            problems.push("link " + found[j]);
    }
    return problems;
}

/** Problems with a release record itself, before any workflow step. */
export function checkRelease(r, allowedDomains) {
    const problems = [];
    const required = [
        ["product_slug", "Product"], ["version", "Version"], ["release_date", "Release date"],
        ["destination_url", "Destination URL"], ["compat_minimum", "Minimum OS or runtime"],
        ["compat_device_class", "Supported devices"], ["licence", "Licence"], ["support_route", "Support route"]
    ];
    for (let i = 0; i < required.length; i++) {
        if (!String(r[required[i][0]] || "").trim())
            problems.push(required[i][1] + " is required");
    }
    if (r.version && !/^[0-9A-Za-z][0-9A-Za-z.-]*$/.test(r.version))
        problems.push("Version may only contain letters, digits, dots and hyphens");
    if (r.release_date && !/^\d{4}-\d{2}-\d{2}$/.test(r.release_date))
        problems.push("Release date must be in YYYY-MM-DD form");
    if (!r.steps || r.steps.length === 0)
        problems.push("Add at least one install or launch step");
    if (!r.notes || r.notes.length === 0)
        problems.push("Add at least one release note");

    if (r.destination_url) {
        const found = checkExternalUrl(r.destination_url, allowedDomains);
        for (let j = 0; j < found.length; j++)
            problems.push("Destination: " + found[j]);
    }
    if ((r.destination_type === "web-app") !== (r.platform === "web"))
        problems.push('The "Web" platform and the "Web application" destination must be used together');
    if (r.destination_type === "store" && r.platform === "linux")
        problems.push("A store destination is not valid for Linux");

    const artifact = [r.artifact_filename, r.artifact_file_type, r.artifact_size_bytes, r.artifact_sha256];
    const filled = artifact.filter((v) => v !== null && v !== undefined && v !== "").length;
    if (r.destination_type === "file") {
        if (filled < 4)
            problems.push("A direct file needs a filename, file type, size and SHA-256 checksum");
        if (r.artifact_sha256 && !/^[0-9a-f]{64}$/.test(r.artifact_sha256))
            problems.push("The SHA-256 checksum must be 64 lowercase hex characters");
        if (r.artifact_size_bytes && !(Number(r.artifact_size_bytes) > 0))
            problems.push("File size must be a positive number of bytes");
        const path = String(r.destination_url || "").split("#")[0].split("?")[0];
        const suffix = "/" + r.artifact_filename;
        if (r.artifact_filename && path.slice(-suffix.length) !== suffix)
            problems.push('The destination does not end with the artifact filename "' + r.artifact_filename + '"');
    } else if (filled > 0) {
        problems.push("Artifact details only apply to a direct file download");
    }
    return problems;
}

/**
 * The workflow steps a signed-in person may take on a release.
 * `needs` names extra input the step requires.
 */
export function releaseSteps(release, role, userId) {
    if (role !== "release_manager" && role !== "admin")
        return [];
    switch (release.status) {
    case "draft":
        return [{ to: "in-review", label: "Submit for review" }];
    case "in-review": {
        const steps = [{ to: "draft", label: "Return to draft" }];
        if (release.prepared_by !== userId)
            steps.unshift({ to: "available", label: "Approve and publish" });
        return steps;
    }
    case "available":
        return [
            { to: "withdrawn", label: "Withdraw", needs: "withdrawn_reason" },
            { to: "superseded", label: "Mark superseded", needs: "superseded_by" },
            { to: "draft", label: "Unpublish to edit" }
        ];
    case "superseded":
        return [{ to: "withdrawn", label: "Withdraw", needs: "withdrawn_reason" }];
    case "withdrawn":
        return [{ to: "draft", label: "Return to draft" }];
    }
    return [];
}

/** Compares "1.10.0" after "1.9.0". Returns <0, 0 or >0. */
export function compareVersions(a, b) {
    const left = String(a).split(/[.-]/);
    const right = String(b).split(/[.-]/);
    for (let i = 0; i < Math.max(left.length, right.length); i++) {
        const x = left[i] === undefined ? "" : left[i];
        const y = right[i] === undefined ? "" : right[i];
        const bothNumbers = /^\d+$/.test(x) && /^\d+$/.test(y);
        const order = bothNumbers ? Number(x) - Number(y) : (x < y ? -1 : x > y ? 1 : 0);
        if (order !== 0)
            return order;
    }
    return 0;
}

/** Newest first: by release date, then by version. */
export function compareReleases(a, b) {
    if (a.release_date !== b.release_date)
        return a.release_date < b.release_date ? 1 : -1;
    return compareVersions(b.version, a.version);
}

const PUBLIC_STATUSES = ["available", "superseded", "withdrawn"];
const CHANNEL_RANK = { stable: 0, beta: 1, preview: 2 };

/** Drafts and releases still in review never reach a public page. */
export function publicReleases(releases) {
    return releases.filter((r) => PUBLIC_STATUSES.indexOf(r.status) >= 0).sort(compareReleases);
}

/** Releases a visitor can act on for a product (and platform), stable channel first. */
export function availableReleases(releases, productSlug, platform) {
    return releases
        .filter((r) => r.status === "available" && r.product_slug === productSlug && (!platform || r.platform === platform))
        .sort((a, b) => (CHANNEL_RANK[a.channel] - CHANNEL_RANK[b.channel]) || compareReleases(a, b));
}

/** "Open [product]" for a web app, "Download for [platform]" for everything else. */
export function actionLabel(release, productName) {
    return release.destination_type === "web-app" ? "Open " + productName : "Download for " + PLATFORMS[release.platform];
}

/** Platforms to list for a product: the ones it targets plus any with a public release. */
export function platformsFor(product, releases) {
    const seen = {};
    for (let i = 0; i < product.platforms.length; i++)
        seen[product.platforms[i]] = true;
    const shown = publicReleases(releases);
    for (let j = 0; j < shown.length; j++) {
        if (shown[j].product_slug === product.slug)
            seen[shown[j].platform] = true;
    }
    return Object.keys(PLATFORMS).filter((p) => seen[p]);
}

export function releasePath(r) {
    return "/downloads/" + r.product_slug + "/" + r.platform + "/" + r.version;
}

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

/** "2026-10-06" (or a timestamp starting with it) becomes "6 October 2026". */
export function formatDate(iso) {
    const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso || "");
    return match ? Number(match[3]) + " " + MONTHS[Number(match[2]) - 1] + " " + match[1] : "";
}

export function formatBytes(bytes) {
    const units = ["bytes", "KB", "MB", "GB"];
    let value = Number(bytes);
    let unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit += 1;
    }
    return (unit === 0 ? value : value.toFixed(1)) + " " + units[unit];
}

/** Options for a select control, from one of the label maps above. */
export function options(labels) {
    return Object.keys(labels).map((value) => ({ value: value, text: labels[value] }));
}

/** Splits an in-app route: "/work?q=gold&status=available" gives the path "/work" and the query as a map. */
export function parseRoute(route) {
    const text = String(route || "/");
    const cut = text.indexOf("?");
    let path = cut < 0 ? text : text.slice(0, cut);
    while (path.length > 1 && path.charAt(path.length - 1) === "/")
        path = path.slice(0, -1);
    const query = {};
    const pairs = cut < 0 ? [] : text.slice(cut + 1).split("&");
    for (let i = 0; i < pairs.length; i++) {
        const eq = pairs[i].indexOf("=");
        const name = eq < 0 ? pairs[i] : pairs[i].slice(0, eq);
        try {
            if (name)
                query[decodeURIComponent(name)] = eq < 0 ? "" : decodeURIComponent(pairs[i].slice(eq + 1).replace(/\+/g, " "));
        } catch (e) {
            // A malformed escape in a hand-edited address: ignore that one value.
        }
    }
    return { path: path || "/", query: query };
}

/** The reverse of parseRoute. Empty values are left out, so a cleared filter leaves a clean address. */
export function buildRoute(path, query) {
    const parts = [];
    const names = Object.keys(query || {});
    for (let i = 0; i < names.length; i++) {
        const value = query[names[i]];
        if (value !== null && value !== undefined && String(value) !== "")
            parts.push(encodeURIComponent(names[i]) + "=" + encodeURIComponent(String(value)));
    }
    return parts.length > 0 ? path + "?" + parts.join("&") : path;
}

export const CATALOG_SORTS = { "": "Featured", "name": "Name: A to Z" };

/** How a product can be used today, from its available releases only: "Web app", "Windows download". */
export function accessFor(product, releases) {
    const found = availableReleases(releases, product.slug, "");
    const labels = [];
    for (let i = 0; i < found.length; i++) {
        const r = found[i];
        const label = r.destination_type === "web-app" ? "Web app"
                    : PLATFORMS[r.platform] + (r.destination_type === "store" ? " app" : " download");
        if (labels.indexOf(label) < 0)
            labels.push(label);
    }
    return labels;
}

/** The filter values that occur in the catalogue, so no chip is offered that could never match. */
export function catalogFacets(products, releases) {
    const platforms = {};
    const statuses = {};
    for (let i = 0; i < products.length; i++) {
        statuses[products[i].status] = true;
        const targets = platformsFor(products[i], releases);
        for (let j = 0; j < targets.length; j++)
            platforms[targets[j]] = true;
    }
    return {
        platforms: Object.keys(PLATFORMS).filter((p) => platforms[p]),
        statuses: Object.keys(PRODUCT_STATUSES).filter((s) => statuses[s])
    };
}

/** How many filters are narrowing the catalogue. The search text and the sort order are not filters. */
export function activeFilterCount(state) {
    return (state.service ? 1 : 0) + (state.platform ? 1 : 0) + (state.status ? 1 : 0);
}

/**
 * The catalogue as a visitor has narrowed it. state: { q, service, platform, status, sort }.
 * Every word of q must appear in the name, category, description, status, platform or service of a product.
 */
export function filterCatalog(products, releases, services, state) {
    const terms = String(state.q || "").toLowerCase().split(/\s+/).filter((t) => t.length > 0);
    const serviceNames = {};
    for (let i = 0; i < services.length; i++)
        serviceNames[services[i].slug] = services[i].name;

    const shown = products.filter((p) => {
        const platforms = platformsFor(p, releases);
        if (state.service && (p.services || []).indexOf(state.service) < 0)
            return false;
        if (state.platform && platforms.indexOf(state.platform) < 0)
            return false;
        if (state.status && p.status !== state.status)
            return false;
        const haystack = [p.public_name, p.internal_name, p.category, p.tagline, p.summary, PRODUCT_STATUSES[p.status]]
            .concat(platforms.map((name) => PLATFORMS[name]))
            .concat((p.services || []).map((slug) => serviceNames[slug] || ""))
            .concat(accessFor(p, releases))
            .join(" ").toLowerCase();
        return terms.every((t) => haystack.indexOf(t) >= 0);
    });
    if (state.sort === "name") {
        shown.sort((a, b) => {
            const x = a.public_name.toLowerCase();
            const y = b.public_name.toLowerCase();
            return x < y ? -1 : x > y ? 1 : 0;
        });
    }
    return shown;
}
