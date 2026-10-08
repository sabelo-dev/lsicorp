pragma Singleton
import QtQuick
import LsiTools
import "rules.mjs" as Rules

// In-app navigation. The route lives in Platform.route, which mirrors the
// browser's address bar, so every page (and every filtered view of a page)
// has a link that can be shared.
QtObject {
    readonly property var parsed: Rules.parseRoute(Platform.route)
    /// The page, without any query: "/work/1145".
    readonly property string path: parsed.path
    readonly property var segments: path.split("/").filter(s => s.length > 0).map(s => decodeURIComponent(s))
    /// View state carried in the address, such as a search or a filter: { q: "gold" }.
    readonly property var query: parsed.query

    function go(target) {
        Platform.route = target;
    }

    /// Updates the view state of the current page. Does not add a history
    /// entry, so Back leaves the page instead of undoing one keystroke.
    function setQuery(query) {
        Platform.replaceRoute(Rules.buildRoute(path, query));
    }

    /// Follows a link from content: a site path, or an external address on the allowlist.
    function follow(link) {
        if (link.charAt(0) === "/" && link.charAt(1) !== "/")
            go(link);
        else if (Store.linkAllowed(link))
            Platform.openExternal(link);
    }
}
