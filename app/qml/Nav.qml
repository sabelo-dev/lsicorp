pragma Singleton
import QtQuick
import LsiTools

// In-app navigation. The path lives in Platform.route, which mirrors the
// browser's address bar, so every page has a link that can be shared.
QtObject {
    readonly property string path: Platform.route
    readonly property var segments: path.split("/").filter(s => s.length > 0).map(s => decodeURIComponent(s))

    function go(target) {
        Platform.route = target;
    }

    /// Follows a link from content: a site path, or an external address on the allowlist.
    function follow(link) {
        if (link.charAt(0) === "/" && link.charAt(1) !== "/")
            go(link);
        else if (Store.linkAllowed(link))
            Platform.openExternal(link);
    }
}
