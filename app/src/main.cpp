#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#ifndef Q_OS_WASM
#include <QCommandLineParser>
#include <QQuickWindow>
#include <QStyleHints>
#include <QTimer>
#endif

#include "platform.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("Lifestyle Investment Corp"));
    QCoreApplication::setApplicationName(QStringLiteral("LSI Tools"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // The typeface is bundled, so the site looks the same in every browser.
    for (const char *weight : { "Regular", "SemiBold", "Bold" })
        QFontDatabase::addApplicationFont(QStringLiteral(":/qt/qml/LsiTools/assets/fonts/Inter-%1.ttf").arg(QLatin1String(weight)));
    QGuiApplication::setFont(QFont(QStringLiteral("Inter")));

#ifndef Q_OS_WASM
    // Desktop builds exist for development: open any route, and optionally
    // save a picture of it and exit (used to check pages without a browser).
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addOptions({
        { QStringLiteral("route"), QStringLiteral("Path to open, e.g. /products/1145."), QStringLiteral("path"), QStringLiteral("/") },
        { QStringLiteral("screenshot"), QStringLiteral("Save a PNG of the window to <file> and exit."), QStringLiteral("file") },
        { QStringLiteral("size"), QStringLiteral("Window size as WIDTHxHEIGHT."), QStringLiteral("size"), QStringLiteral("1200x800") },
        { QStringLiteral("dark"), QStringLiteral("Use the dark colour scheme.") },
    });
    parser.process(app);
    Platform::initialRoute = parser.value(QStringLiteral("route"));
    if (parser.isSet(QStringLiteral("dark")))
        QGuiApplication::styleHints()->setColorScheme(Qt::ColorScheme::Dark);
#endif

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("LsiTools", "Main");

#ifndef Q_OS_WASM
    if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0))) {
        const QStringList size = parser.value(QStringLiteral("size")).split(u'x');
        if (size.size() == 2)
            window->resize(size.at(0).toInt(), size.at(1).toInt());
        if (parser.isSet(QStringLiteral("screenshot"))) {
            const QString file = parser.value(QStringLiteral("screenshot"));
            QTimer::singleShot(2500, window, [window, file] {
                QCoreApplication::exit(window->grabWindow().save(file) ? 0 : 2);
            });
        }
    }
#endif

    return app.exec();
}
