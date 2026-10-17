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

#ifndef NIGHTLIGHT_H
#define NIGHTLIGHT_H

#include <QObject>
#include <QDBusInterface>

// Night light settings, kept by lingmo-settings-daemon (/NightLight)
class NightLight : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(bool active READ active NOTIFY changed)
    Q_PROPERTY(int temperature READ temperature WRITE setTemperature NOTIFY changed)
    Q_PROPERTY(int minTemperature READ minTemperature NOTIFY changed)
    Q_PROPERTY(int maxTemperature READ maxTemperature NOTIFY changed)
    // 0: always on, 1: from startTime to endTime
    Q_PROPERTY(int mode READ mode WRITE setMode NOTIFY changed)
    Q_PROPERTY(QString startTime READ startTime NOTIFY changed)
    Q_PROPERTY(QString endTime READ endTime NOTIFY changed)

public:
    explicit NightLight(QObject *parent = nullptr);

    bool available() const { return m_available; }
    bool enabled() const { return m_enabled; }
    bool active() const { return m_active; }
    int temperature() const { return m_temperature; }
    int minTemperature() const { return m_minTemperature; }
    int maxTemperature() const { return m_maxTemperature; }
    int mode() const { return m_mode; }
    QString startTime() const { return m_startTime; }
    QString endTime() const { return m_endTime; }

    void setEnabled(bool enabled);
    void setTemperature(int temperature);
    void setMode(int mode);

    // Times as "HH:mm"; returns false when one of them is not a valid time
    Q_INVOKABLE bool setSchedule(const QString &startTime, const QString &endTime);

signals:
    void changed();

private slots:
    void reload();

private:
    QDBusInterface m_iface;
    bool m_available = false;
    bool m_enabled = false;
    bool m_active = false;
    int m_temperature = 4000;
    int m_minTemperature = 2500;
    int m_maxTemperature = 6500;
    int m_mode = 0;
    QString m_startTime = QStringLiteral("19:00");
    QString m_endTime = QStringLiteral("07:00");
};

#endif // NIGHTLIGHT_H
