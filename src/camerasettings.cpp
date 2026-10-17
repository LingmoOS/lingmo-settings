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

#include "camerasettings.h"

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusServiceWatcher>
#include <QProcess>
#include <QUrl>

namespace {
const QString Service = "com.lingmo.Camera";
const QString Path = "/Camera";
const QString Interface = "com.lingmo.Camera";
}

CameraSettings::CameraSettings(QObject *parent)
    : QObject(parent)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.connect(Service, Path, Interface, "Changed", this, SLOT(reload()));

    auto *watcher = new QDBusServiceWatcher(Service, bus,
                                            QDBusServiceWatcher::WatchForOwnerChange, this);
    connect(watcher, &QDBusServiceWatcher::serviceOwnerChanged, this, &CameraSettings::reload);

    reload();
}

void CameraSettings::reload()
{
    QDBusInterface iface(Service, Path, Interface, QDBusConnection::sessionBus());
    m_running = QDBusConnection::sessionBus().interface()->isServiceRegistered(Service);
    if (m_running) {
        m_available = iface.property("Available").toBool();
        m_active = iface.property("Active").toBool();
        m_framing = iface.property("Framing").toBool();
        m_zoom = iface.property("Zoom").toString();
        m_source = iface.property("Source").toString();
        m_backgroundBlur = iface.property("BackgroundBlur").toBool();
        m_blurStrength = iface.property("BlurStrength").toString();
        m_backgroundImage = iface.property("BackgroundImage").toString();

        m_cameras.clear();
        const QDBusReply<QStringList> reply = iface.call("Cameras");
        for (const QString &entry : reply.value()) {
            const int bar = entry.indexOf('|');
            m_cameras << QVariantMap{{"device", entry.left(bar)}, {"name", entry.mid(bar + 1)}};
        }
    } else {
        m_available = m_active = false;
        m_cameras.clear();
    }
    emit changed();
}

void CameraSettings::set(const QString &name, const QVariant &value)
{
    QDBusInterface iface(Service, Path, Interface, QDBusConnection::sessionBus());
    iface.setProperty(name.toUtf8().constData(), value);
}

void CameraSettings::setFraming(bool on)
{
    set("Framing", on);
}

void CameraSettings::setZoom(const QString &zoom)
{
    set("Zoom", zoom);
}

void CameraSettings::setSource(const QString &device)
{
    set("Source", device);
}

void CameraSettings::setBackgroundBlur(bool on)
{
    set("BackgroundBlur", on);
}

void CameraSettings::setBlurStrength(const QString &strength)
{
    set("BlurStrength", strength);
}

void CameraSettings::setBackgroundImage(const QString &path)
{
    set("BackgroundImage", path.startsWith("file:") ? QUrl(path).toLocalFile() : path);
}

void CameraSettings::start()
{
    if (!m_running)
        QProcess::startDetached("lingmo-camera", {});
}
