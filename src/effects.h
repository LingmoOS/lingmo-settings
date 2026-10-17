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

#ifndef EFFECTS_H
#define EFFECTS_H

#include <QObject>

class QSettings;

// KWin effects, the Alt+Tab layout and the hot corners, for the Effects page. Effects
// are turned on and off in kwinrc's [Plugins] group and KWin is told to reload.
class Effects : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString switcherLayout READ switcherLayout WRITE setSwitcherLayout NOTIFY switcherLayoutChanged)
    Q_PROPERTY(int revision READ revision NOTIFY changed)

public:
    explicit Effects(QObject *parent = nullptr);

    // Current state: kwinrc, or the effect's own default when kwinrc doesn't say
    Q_INVOKABLE bool isEnabled(const QString &id) const;
    Q_INVOKABLE void setEnabled(const QString &id, bool enabled);
    // Several at once (e.g. switching from one open/close animation to another)
    Q_INVOKABLE void setEnabledMany(const QVariantMap &states);
    // False when KWin can't run it here (no GPU acceleration)
    Q_INVOKABLE bool isSupported(const QString &id) const;

    // Hot corners: corner is "TopLeft", "TopRight", "BottomLeft" or "BottomRight"; action
    // is "none", "overview", "windowview", "showdesktop", "launcher" or "lockscreen"
    Q_INVOKABLE QString cornerAction(const QString &corner) const;
    Q_INVOKABLE void setCornerAction(const QString &corner, const QString &action);

    QString switcherLayout() const;
    void setSwitcherLayout(const QString &layout);

    // Bumped on every change, so QML bindings on isEnabled() re-evaluate
    int revision() const;

signals:
    void switcherLayoutChanged();
    void changed();

private:
    bool defaultEnabled(const QString &id) const;
    void reloadKWin();

    QSettings *m_kwinrc;
    int m_revision = 0;
};

#endif // EFFECTS_H
