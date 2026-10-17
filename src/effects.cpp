/*
 * Copyright (C) 2026 LingmoOS Team.
 *
 * Author:     devalexandre <alexandre@dev2learn.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "effects.h"

#include <QDBusInterface>
#include <QDir>
#include <QDBusReply>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QSettings>
#include <QStandardPaths>
#include <QVariantMap>

#include <KConfig>
#include <KConfigGroup>

#include <optional>

// KWin's ElectricBorder numbers for the corners; 9 is ElectricNone
static const QMap<QString, int> s_corners = {
    {QStringLiteral("TopRight"), 1},
    {QStringLiteral("BottomRight"), 3},
    {QStringLiteral("BottomLeft"), 5},
    {QStringLiteral("TopLeft"), 7},
};
static constexpr int s_noBorder = 9;

// kwinrc lists of borders that trigger something. A corner is taken out of every
// one of them before it gets its new action, so it never does two things at once.
struct BorderList {
    const char *group;
    const char *key;
    const char *action;  // the hot corner choice this list stands for, if any
    const char *plugin;  // effect or script that has to be on for it to work
    QList<int> defaults; // KWin's default when kwinrc doesn't say
};
static const BorderList s_borderLists[] = {
    {"Effect-overview", "BorderActivate", "overview", "overview", {7}},
    {"Effect-overview", "GridBorderActivate", nullptr, nullptr, {}},
    {"Effect-windowview", "BorderActivate", "windowview", "windowview", {}},
    {"Effect-windowview", "BorderActivateAll", nullptr, nullptr, {}},
    {"Effect-windowview", "BorderActivateClass", nullptr, nullptr, {}},
    {"Effect-windowview", "BorderActivateClassCurrentDesktop", nullptr, nullptr, {}},
    {"TabBox", "BorderActivate", nullptr, nullptr, {}},
    {"TabBox", "BorderAlternativeActivate", nullptr, nullptr, {}},
    // lingmo-kwin-plugins' linghotcorners script
    {"Script-linghotcorners", "Launcher", "launcher", "linghotcorners", {}},
    {"Script-linghotcorners", "LockScreen", "lockscreen", "linghotcorners", {}},
};

Effects::Effects(QObject *parent)
    : QObject(parent)
    , m_kwinrc(new QSettings(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/kwinrc",
                             QSettings::IniFormat, this))
{
}

bool Effects::defaultEnabled(const QString &id) const
{
    // Built-in effects, scripted effects and Lingmo's own scripts all carry
    // KPlugin.EnabledByDefault in their metadata
    const QStringList candidates = {
        QStringLiteral("kwin-x11/builtin-effects/%1.json").arg(id),
        QStringLiteral("kwin-x11/effects/%1/metadata.json").arg(id),
        QStringLiteral("kwin/effects/%1/metadata.json").arg(id),
        QStringLiteral("kwin/scripts/%1/metadata.json").arg(id),
        QStringLiteral("kwin-x11/scripts/%1/metadata.json").arg(id),
    };
    const auto enabledByDefault = [](const QString &path, const QString &id, bool checkId) -> std::optional<bool> {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly))
            return std::nullopt;
        const QJsonObject plugin = QJsonDocument::fromJson(file.readAll()).object().value("KPlugin").toObject();
        if (checkId && plugin.value("Id").toString() != id)
            return std::nullopt;
        return plugin.value("EnabledByDefault").toBool(false);
    };

    for (const QString &candidate : candidates) {
        const QString path = QStandardPaths::locate(QStandardPaths::GenericDataLocation, candidate);
        if (!path.isEmpty()) {
            if (const auto value = enabledByDefault(path, id, false))
                return *value;
        }
    }

    // Packages whose directory isn't named after their id (Lingmo's ling_popups is lingmo_popups)
    for (const QString &base : {QStringLiteral("kwin/effects"), QStringLiteral("kwin-x11/effects")}) {
        const QStringList roots = QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, base, QStandardPaths::LocateDirectory);
        for (const QString &root : roots) {
            const QStringList packages = QDir(root).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString &package : packages) {
                if (const auto value = enabledByDefault(root + '/' + package + "/metadata.json", id, true))
                    return *value;
            }
        }
    }
    return false;
}

bool Effects::isEnabled(const QString &id) const
{
    // The user's kwinrc, then the system ones (Lingmo's defaults live in
    // /etc/xdg/kwinrc), then the effect's own default
    const QStringList files = QStandardPaths::locateAll(QStandardPaths::GenericConfigLocation, QStringLiteral("kwinrc"));
    for (const QString &path : files) {
        QSettings kwinrc(path, QSettings::IniFormat);
        const QVariant value = kwinrc.value("Plugins/" + id + "Enabled");
        if (value.isValid())
            return value.toBool();
    }
    return defaultEnabled(id);
}

void Effects::setEnabledMany(const QVariantMap &states)
{
    m_kwinrc->beginGroup("Plugins");
    for (auto it = states.cbegin(); it != states.cend(); ++it)
        m_kwinrc->setValue(it.key() + "Enabled", it.value().toBool());
    m_kwinrc->endGroup();
    m_kwinrc->sync();
    reloadKWin();
    ++m_revision;
    emit changed();
}

void Effects::setEnabled(const QString &id, bool enabled)
{
    setEnabledMany({{id, enabled}});
}

bool Effects::isSupported(const QString &id) const
{
    QDBusInterface effects("org.kde.KWin", "/Effects", "org.kde.kwin.Effects");
    if (!effects.isValid())
        return true;
    const QDBusReply<bool> reply = effects.call("isEffectSupported", id);
    return !reply.isValid() || reply.value();
}

QString Effects::cornerAction(const QString &corner) const
{
    if (!s_corners.contains(corner))
        return QStringLiteral("none");
    const int border = s_corners.value(corner);

    // Reads the user's kwinrc over the system ones, like KWin
    KConfig kwinrc(QStringLiteral("kwinrc"));
    const QString builtin = kwinrc.group(QStringLiteral("ElectricBorders")).readEntry(corner, QString()).toLower();
    if (builtin == QLatin1String("showdesktop"))
        return QStringLiteral("showdesktop");

    for (const BorderList &list : s_borderLists) {
        if (list.action && kwinrc.group(list.group).readEntry(list.key, list.defaults).contains(border))
            return QString::fromLatin1(list.action);
    }
    return QStringLiteral("none");
}

void Effects::setCornerAction(const QString &corner, const QString &action)
{
    if (!s_corners.contains(corner) || action == cornerAction(corner))
        return;
    const int border = s_corners.value(corner);

    KConfig kwinrc(QStringLiteral("kwinrc"));
    KConfigGroup builtin = kwinrc.group(QStringLiteral("ElectricBorders"));
    const QString builtinAction = action == QLatin1String("showdesktop") ? QStringLiteral("ShowDesktop") : QStringLiteral("None");
    if (builtin.readEntry(corner, QStringLiteral("None")) != builtinAction)
        builtin.writeEntry(corner, builtinAction);

    QString plugin;
    for (const BorderList &list : s_borderLists) {
        KConfigGroup group = kwinrc.group(list.group);
        // 0..7 are the edges and corners: drop "none" (8, 9) and duplicates
        QList<int> current;
        for (int value : group.readEntry(list.key, list.defaults)) {
            if (value >= 0 && value < 8 && !current.contains(value))
                current << value;
        }
        QList<int> borders = current;
        borders.removeAll(border);
        if (list.action && action == QLatin1String(list.action)) {
            borders << border;
            plugin = QString::fromLatin1(list.plugin);
        }
        if (borders != current)
            group.writeEntry(list.key, borders.isEmpty() ? QList<int>{s_noBorder} : borders);
    }

    // A corner can't work while its effect or script is off
    if (!plugin.isEmpty() && !isEnabled(plugin))
        kwinrc.group(QStringLiteral("Plugins")).writeEntry(plugin + QStringLiteral("Enabled"), true);

    kwinrc.sync();
    m_kwinrc->sync();
    reloadKWin();
    ++m_revision;
    emit changed();
}

QString Effects::switcherLayout() const
{
    m_kwinrc->beginGroup("TabBox");
    const QString layout = m_kwinrc->value("LayoutName", "lingmo_carousel").toString();
    m_kwinrc->endGroup();
    return layout;
}

void Effects::setSwitcherLayout(const QString &layout)
{
    if (layout == switcherLayout())
        return;
    m_kwinrc->beginGroup("TabBox");
    m_kwinrc->setValue("LayoutName", layout);
    m_kwinrc->endGroup();
    m_kwinrc->sync();
    reloadKWin();
    emit switcherLayoutChanged();
}

int Effects::revision() const
{
    return m_revision;
}

void Effects::reloadKWin()
{
    QDBusInterface("org.kde.KWin", "/KWin", "org.kde.KWin").call("reconfigure");
}
