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

#include "nightlight.h"

#include <QDBusConnection>
#include <QDBusServiceWatcher>
#include <QDBusPendingCall>
#include <QTime>

static const QString s_service = QStringLiteral("com.lingmo.Settings");
static const QString s_path = QStringLiteral("/NightLight");
static const QString s_interface = QStringLiteral("com.lingmo.NightLight");

NightLight::NightLight(QObject *parent)
    : QObject(parent)
    , m_iface(s_service, s_path, s_interface, QDBusConnection::sessionBus())
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    for (const char *signal : { "enabledChanged", "activeChanged", "temperatureChanged", "modeChanged", "scheduleChanged" })
        bus.connect(s_service, s_path, s_interface, signal, this, SLOT(reload()));

    auto *watcher = new QDBusServiceWatcher(s_service, bus, QDBusServiceWatcher::WatchForOwnerChange, this);
    connect(watcher, &QDBusServiceWatcher::serviceOwnerChanged, this, &NightLight::reload);

    reload();
}

void NightLight::reload()
{
    QDBusInterface iface(s_service, s_path, s_interface, QDBusConnection::sessionBus());
    const QVariant supported = iface.property("supported");

    m_available = supported.isValid() && supported.toBool();
    if (m_available) {
        m_enabled = iface.property("enabled").toBool();
        m_active = iface.property("active").toBool();
        m_temperature = iface.property("temperature").toInt();
        m_minTemperature = iface.property("minTemperature").toInt();
        m_maxTemperature = iface.property("maxTemperature").toInt();
        m_mode = iface.property("mode").toInt();
        m_startTime = iface.property("startTime").toString();
        m_endTime = iface.property("endTime").toString();
    }

    emit changed();
}

void NightLight::setEnabled(bool enabled)
{
    m_enabled = enabled;
    m_iface.asyncCall("setEnabled", enabled);
    emit changed();
}

void NightLight::setTemperature(int temperature)
{
    m_temperature = temperature;
    m_iface.asyncCall("setTemperature", temperature);
    emit changed();
}

void NightLight::setMode(int mode)
{
    m_mode = mode;
    m_iface.asyncCall("setMode", mode);
    emit changed();
}

bool NightLight::setSchedule(const QString &startTime, const QString &endTime)
{
    // Accept "7:00" as well as "07:00"
    const QTime start = QTime::fromString(startTime.trimmed(), "H:mm");
    const QTime end = QTime::fromString(endTime.trimmed(), "H:mm");
    if (!start.isValid() || !end.isValid())
        return false;

    m_startTime = start.toString("HH:mm");
    m_endTime = end.toString("HH:mm");
    m_iface.asyncCall("setSchedule", m_startTime, m_endTime);
    emit changed();
    return true;
}
