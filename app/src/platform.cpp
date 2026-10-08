#include "platform.h"

#include <QDesktopServices>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QUrl>

#ifdef Q_OS_WASM
#include <emscripten/bind.h>
#include <emscripten/val.h>
using emscripten::val;
#endif

QString Platform::initialRoute = QStringLiteral("/");
QString Platform::initialAction;
bool Platform::forceDark = false;

namespace {

Platform *instance = nullptr;

QString normalised(QString route)
{
    while (route.startsWith(u'#'))
        route.remove(0, 1);
    if (!route.startsWith(u'/'))
        route.prepend(u'/');
    while (route.size() > 1 && route.endsWith(u'/'))
        route.chop(1);
    return route;
}

#ifdef Q_OS_WASM
QString browserRoute()
{
    return normalised(QString::fromStdString(val::global("location")["hash"].as<std::string>()));
}

void onHashChange(val)
{
    if (instance)
        instance->syncFromBrowser();
}

EMSCRIPTEN_BINDINGS(lsitools)
{
    emscripten::function("lsiHashChanged", &onHashChange);
}
#endif

QVariantMap readConfig()
{
#ifdef Q_OS_WASM
    // web/config.js sets window.LSI_CONFIG before the app starts.
    const val config = val::global("LSI_CONFIG");
    if (config.isUndefined() || config.isNull())
        return {};
    const std::string json = val::global("JSON").call<std::string>("stringify", config);
    return QJsonDocument::fromJson(QByteArray::fromStdString(json)).object().toVariantMap();
#else
    QVariantMap config;
    QFile file(QStringLiteral("config.json"));
    if (file.open(QIODevice::ReadOnly))
        config = QJsonDocument::fromJson(file.readAll()).object().toVariantMap();
    if (qEnvironmentVariableIsSet("LSI_SUPABASE_URL"))
        config[QStringLiteral("supabaseUrl")] = qEnvironmentVariable("LSI_SUPABASE_URL");
    if (qEnvironmentVariableIsSet("LSI_SUPABASE_KEY"))
        config[QStringLiteral("supabaseKey")] = qEnvironmentVariable("LSI_SUPABASE_KEY");
    return config;
#endif
}

} // namespace

Platform::Platform(QObject *parent)
    : QObject(parent)
    , m_config(readConfig())
{
    instance = this;
#ifdef Q_OS_WASM
    m_route = browserRoute();
    val::global("window").call<void>("addEventListener", std::string("hashchange"),
                                     val::module_property("lsiHashChanged"));
#else
    m_route = normalised(initialRoute);
#endif
}

Platform::~Platform()
{
    if (instance == this)
        instance = nullptr;
}

bool Platform::browser() const
{
#ifdef Q_OS_WASM
    return true;
#else
    return false;
#endif
}

bool Platform::reducedMotion() const
{
#ifdef Q_OS_WASM
    return val::global("window").call<val>("matchMedia", std::string("(prefers-reduced-motion: reduce)"))["matches"].as<bool>();
#else
    return qEnvironmentVariableIsSet("LSI_REDUCED_MOTION");
#endif
}

bool Platform::apple() const
{
#ifdef Q_OS_WASM
    // iPhone and iPad user agents also say "like Mac OS X".
    return QString::fromStdString(val::global("navigator")["userAgent"].as<std::string>()).contains(QLatin1String("Mac"));
#elif defined(Q_OS_MACOS)
    return true;
#else
    return false;
#endif
}

void Platform::replaceRoute(const QString &route)
{
    const QString next = normalised(route);
    if (next == m_route)
        return;
    m_route = next;
#ifdef Q_OS_WASM
    val::global("history").call<void>("replaceState", val::null(), std::string(), (QStringLiteral("#") + next).toStdString());
#endif
    emit routeChanged();
}

void Platform::setRoute(const QString &route)
{
    const QString next = normalised(route);
    if (next == m_route)
        return;
    m_route = next;
#ifdef Q_OS_WASM
    // Adds a history entry, so the browser's back button works inside the app.
    val::global("location").set("hash", next.toStdString());
#endif
    emit routeChanged();
}

void Platform::syncFromBrowser()
{
#ifdef Q_OS_WASM
    const QString next = browserRoute();
    if (next == m_route)
        return;
    m_route = next;
    emit routeChanged();
#endif
}

void Platform::setTitle(const QString &title)
{
#ifdef Q_OS_WASM
    val::global("document").set("title", title.toStdString());
#else
    Q_UNUSED(title)
#endif
}

void Platform::openExternal(const QString &url)
{
    const QUrl target(url, QUrl::StrictMode);
    if (!target.isValid() || target.scheme() != QLatin1String("https"))
        return;
#ifdef Q_OS_WASM
    // Navigating this tab is never caught by a pop-up blocker.
    val::global("location").call<void>("assign", target.toString(QUrl::FullyEncoded).toStdString());
#else
    QDesktopServices::openUrl(target);
#endif
}

QString Platform::seed() const
{
    QFile file(QStringLiteral(":/qt/qml/LsiTools/seed/seed.json"));
    return file.open(QIODevice::ReadOnly) ? QString::fromUtf8(file.readAll()) : QString();
}

QString Platform::stored(const QString &key) const
{
    return QSettings().value(key).toString();
}

void Platform::store(const QString &key, const QString &value)
{
    QSettings settings;
    if (value.isEmpty())
        settings.remove(key);
    else
        settings.setValue(key, value);
}
