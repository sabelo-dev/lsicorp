pragma Singleton
import QtQuick
import LsiTools

// Minimal Supabase client: PostgREST for data and GoTrue for staff sign-in.
// Only the public anon key is ever used here. What a request may read or
// change is decided by row-level security in the database, not by this file.
//
// Every call takes done(error, data); error is null or { status, message }.
QtObject {
    id: root

    readonly property string url: String(Platform.config.supabaseUrl || "").replace(/\/+$/, "")
    readonly property string key: String(Platform.config.supabaseKey || "")
    /// The site's tables live in their own schema, so it can share a project with another app.
    readonly property string schema: "lsicorp"
    readonly property bool configured: /^https:\/\/|^http:\/\/(localhost|127\.0\.0\.1)[:\/]/.test(url) && key !== ""

    /// { access_token, refresh_token, expires_at, user: { id, email } } or null.
    property var session: null
    readonly property bool signedIn: session !== null
    readonly property string userId: session ? session.user.id : ""
    readonly property string userEmail: session ? session.user.email : ""

    Component.onCompleted: {
        const saved = Platform.stored("session");
        if (!configured || !saved)
            return;
        try {
            session = JSON.parse(saved);
        } catch (e) {
            Platform.store("session", "");
        }
    }

    function send(method, path, body, headers, token, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let data = null;
            try {
                data = xhr.responseText ? JSON.parse(xhr.responseText) : null;
            } catch (e) {
                data = null;
            }
            if (xhr.status >= 200 && xhr.status < 300) {
                done(null, data);
                return;
            }
            const message = data && (data.message || data.msg || data.error_description || data.error);
            done({
                status: xhr.status,
                message: message || (xhr.status === 0 ? "The service could not be reached. Check your connection and try again."
                                                      : "The request failed (" + xhr.status + ").")
            }, null);
        };
        xhr.open(method, url + path);
        xhr.setRequestHeader("apikey", key);
        if (token)
            xhr.setRequestHeader("Authorization", "Bearer " + token);
        if (body !== null)
            xhr.setRequestHeader("Content-Type", "application/json");
        for (const name in headers)
            xhr.setRequestHeader(name, headers[name]);
        xhr.send(body === null ? undefined : JSON.stringify(body));
    }

    function setSession(next) {
        session = next;
        Platform.store("session", next ? JSON.stringify(next) : "");
    }

    function adopt(data) {
        setSession({
            access_token: data.access_token,
            refresh_token: data.refresh_token,
            expires_at: Math.floor(Date.now() / 1000) + (data.expires_in || 3600),
            user: { id: data.user.id, email: data.user.email }
        });
    }

    /// Calls ready(token) with a valid access token, refreshing it first if it is about to expire.
    function withToken(ready) {
        if (!session) {
            ready("");
            return;
        }
        if (session.expires_at - Date.now() / 1000 > 60) {
            ready(session.access_token);
            return;
        }
        send("POST", "/auth/v1/token?grant_type=refresh_token", { refresh_token: session.refresh_token }, {}, "", function (error, data) {
            if (error)
                setSession(null);
            else
                adopt(data);
            ready(session ? session.access_token : "");
        });
    }

    function rest(method, table, query, body, done, quiet) {
        withToken(function (token) {
            const headers = method === "GET" ? { "Accept-Profile": schema }
                                             : { "Content-Profile": schema, "Prefer": quiet ? "return=minimal" : "return=representation" };
            send(method, "/rest/v1/" + table + (query ? "?" + query : ""), body, headers, token, function (error, data) {
                // Row-level security hides rows rather than failing, so a write that
                // touched nothing is reported as the refusal it is.
                if (!error && method !== "GET" && method !== "POST" && Array.isArray(data) && data.length === 0)
                    done({ status: 403, message: "Nothing was changed. The record no longer exists or your role does not allow this." }, null);
                else
                    done(error, data);
            });
        });
    }

    function select(table, query, done) {
        rest("GET", table, query, null, done);
    }

    function insert(table, row, done) {
        rest("POST", table, "", row, done);
    }

    /// Adds a row without reading it back, for callers who may insert but not select.
    function insertQuiet(table, row, done) {
        rest("POST", table, "", row, done, true);
    }

    function update(table, filter, changes, done) {
        rest("PATCH", table, filter, changes, done);
    }

    function remove(table, filter, done) {
        rest("DELETE", table, filter, null, done);
    }

    /// Builds "column=eq.value&..." for the given key columns of a row.
    function match(row, columns) {
        return columns.map(c => c + "=eq." + encodeURIComponent(row[c])).join("&");
    }

    function signIn(email, password, done) {
        send("POST", "/auth/v1/token?grant_type=password", { email: email, password: password }, {}, "", function (error, data) {
            if (!error)
                adopt(data);
            done(error);
        });
    }

    function signOut() {
        if (session)
            send("POST", "/auth/v1/logout", null, {}, session.access_token, function () {});
        setSession(null);
    }
}
