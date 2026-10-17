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

#include "keyboardlayouts.h"

#include <QDBusConnection>
#include <QDBusServiceWatcher>
#include <QDBusPendingCall>
#include <QFile>

#include <libintl.h>

static const QString s_service = QStringLiteral("com.lingmo.Settings");
static const QString s_path = QStringLiteral("/Keyboard");
static const QString s_interface = QStringLiteral("com.lingmo.Keyboard");

// XKB holds at most four groups
static const int s_maxLayouts = 4;

KeyboardLayouts::KeyboardLayouts(QObject *parent)
    : QObject(parent)
    , m_iface(s_service, s_path, s_interface, QDBusConnection::sessionBus())
{
    loadCatalog();

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.connect(s_service, s_path, s_interface, "layoutsChanged", this, SLOT(reload()));
    bus.connect(s_service, s_path, s_interface, "switchOptionChanged", this, SLOT(reload()));

    auto *watcher = new QDBusServiceWatcher(s_service, bus, QDBusServiceWatcher::WatchForOwnerChange, this);
    connect(watcher, &QDBusServiceWatcher::serviceOwnerChanged, this, &KeyboardLayouts::reload);

    reload();
}

void KeyboardLayouts::reload()
{
    QDBusInterface iface(s_service, s_path, s_interface, QDBusConnection::sessionBus());
    const QVariant layouts = iface.property("layouts");

    m_available = layouts.isValid();
    m_layouts = layouts.toStringList();
    m_shortNames = iface.property("shortNames").toStringList();
    m_switchOption = iface.property("switchOption").toString();

    emit changed();
}

QStringList KeyboardLayouts::descriptions() const
{
    QStringList list;

    for (const QString &id : m_layouts)
        list << m_catalog.value(id, id);

    return list;
}

QVariantList KeyboardLayouts::switchOptions() const
{
    const QList<QPair<QString, QString>> options = {
        { "", tr("None") },
        { "grp:alt_shift_toggle", tr("Alt+Shift") },
        { "grp:ctrl_shift_toggle", tr("Ctrl+Shift") },
        { "grp:win_space_toggle", tr("Super+Space") },
        { "grp:alt_space_toggle", tr("Alt+Space") },
        { "grp:shifts_toggle", tr("Both Shift keys") },
        { "grp:caps_toggle", tr("Caps Lock") },
        { "grp:toggle", tr("Right Alt") },
        { "grp:menu_toggle", tr("Menu key") },
    };

    QVariantList list;
    for (const auto &option : options)
        list << QVariantMap { { "id", option.first }, { "name", option.second } };

    return list;
}

QVariantList KeyboardLayouts::search(const QString &text) const
{
    const QString needle = text.trimmed();
    QVariantList list;

    for (const QString &id : m_catalogIds) {
        if (m_layouts.contains(id))
            continue;

        const QString description = m_catalog.value(id);
        if (!needle.isEmpty() && !description.contains(needle, Qt::CaseInsensitive)
                && !id.startsWith(needle, Qt::CaseInsensitive))
            continue;

        list << QVariantMap { { "id", id }, { "description", description } };
    }

    return list;
}

void KeyboardLayouts::add(const QString &id)
{
    if (m_layouts.contains(id) || m_layouts.size() >= s_maxLayouts)
        return;

    save(m_layouts + QStringList { id });
}

void KeyboardLayouts::remove(int index)
{
    if (index < 0 || index >= m_layouts.size() || m_layouts.size() <= 1)
        return;

    QStringList list = m_layouts;
    list.removeAt(index);
    save(list);
}

void KeyboardLayouts::move(int from, int to)
{
    if (from < 0 || from >= m_layouts.size() || to < 0 || to >= m_layouts.size() || from == to)
        return;

    QStringList list = m_layouts;
    list.move(from, to);
    save(list);
}

void KeyboardLayouts::setSwitchOption(const QString &option)
{
    m_switchOption = option;
    m_iface.asyncCall("setSwitchOption", option);
    emit changed();
}

void KeyboardLayouts::save(const QStringList &layouts)
{
    m_layouts = layouts;
    m_iface.asyncCall("setLayouts", layouts);
    emit changed();
}

void KeyboardLayouts::loadCatalog()
{
    QFile file("/usr/share/X11/xkb/rules/evdev.lst");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    // "! layout":  "  br   Portuguese (Brazil)"
    // "! variant": "  intl us: English (US, intl., with dead keys)"
    QString section;
    while (!file.atEnd()) {
        const QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (line.startsWith('!')) {
            section = line.mid(1).trimmed();
            continue;
        }
        if (line.isEmpty() || (section != "layout" && section != "variant"))
            continue;

        const QString name = line.section(' ', 0, 0);
        QString description = line.section(' ', 1).trimmed();
        QString id = name;

        if (section == "variant") {
            id = QString("%1(%2)").arg(description.section(':', 0, 0), name);
            description = description.section(':', 1).trimmed();
        }

        m_catalogIds << id;
        m_catalog.insert(id, QString::fromUtf8(dgettext("xkeyboard-config", description.toUtf8().constData())));
    }

    // Alphabetical by the (translated) name
    std::sort(m_catalogIds.begin(), m_catalogIds.end(), [this](const QString &a, const QString &b) {
        return QString::localeAwareCompare(m_catalog.value(a), m_catalog.value(b)) < 0;
    });
}
