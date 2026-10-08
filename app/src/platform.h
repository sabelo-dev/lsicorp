#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

// The few things QML cannot do by itself: talk to the browser (address bar,
// page title, navigation), read deployment config and keep small values
// between visits. In a desktop build the same API is backed by local
// equivalents so the app can be run and tested without a browser.
class Platform : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString route READ route WRITE setRoute NOTIFY routeChanged)
    Q_PROPERTY(QVariantMap config READ config CONSTANT)
    Q_PROPERTY(bool browser READ browser CONSTANT)
    Q_PROPERTY(bool reducedMotion READ reducedMotion CONSTANT)
    Q_PROPERTY(bool apple READ apple CONSTANT)
    Q_PROPERTY(QString devAction READ devAction CONSTANT)
    Q_PROPERTY(bool devDark READ devDark CONSTANT)

public:
    explicit Platform(QObject *parent = nullptr);
    ~Platform() override;

    /// Current in-app path, e.g. "/products/1145". Mirrors the URL fragment in a browser.
    QString route() const { return m_route; }
    void setRoute(const QString &route);

    /// Deployment settings: supabaseUrl and supabaseKey (the public anon key).
    QVariantMap config() const { return m_config; }

    bool browser() const;
    /// True when the visitor has asked their system for less animation.
    bool reducedMotion() const;

    /// True on Apple devices, where shortcuts are shown with the Command key.
    bool apple() const;

    /// Changes the route without adding a history entry. For state such as a
    /// search or filter, where Back should leave the page, not undo a keystroke.
    Q_INVOKABLE void replaceRoute(const QString &route);
    Q_INVOKABLE void setTitle(const QString &title);
    /// Leaves the app for an external address. Callers check the allowlist first.
    Q_INVOKABLE void openExternal(const QString &url);
    Q_INVOKABLE QString seed() const;
    Q_INVOKABLE QString stored(const QString &key) const;
    Q_INVOKABLE void store(const QString &key, const QString &value);

    /// Picks up a route changed by the browser (back, forward, edited address).
    void syncFromBrowser();

    /// Route to open at startup in a desktop build.
    static QString initialRoute;
    /// Desktop builds only: something to do once loaded, such as "search" or "menu" to open that panel for a screenshot.
    static QString initialAction;
    QString devAction() const { return initialAction; }
    /// Desktop builds only: render in the dark scheme (the --dark option), whatever the system says.
    static bool forceDark;
    bool devDark() const { return forceDark; }

signals:
    void routeChanged();

private:
    QString m_route;
    QVariantMap m_config;
};
