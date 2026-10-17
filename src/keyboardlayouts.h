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

#ifndef KEYBOARDLAYOUTS_H
#define KEYBOARDLAYOUTS_H

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QDBusInterface>

// Keyboard layout list and switch shortcut, applied by lingmo-settings-daemon (/Keyboard)
class KeyboardLayouts : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY changed)
    // "br", "us(intl)"…
    Q_PROPERTY(QStringList layouts READ layouts NOTIFY changed)
    Q_PROPERTY(QStringList descriptions READ descriptions NOTIFY changed)
    Q_PROPERTY(QStringList shortNames READ shortNames NOTIFY changed)
    Q_PROPERTY(QString switchOption READ switchOption NOTIFY changed)
    Q_PROPERTY(QVariantList switchOptions READ switchOptions CONSTANT)

public:
    explicit KeyboardLayouts(QObject *parent = nullptr);

    bool available() const { return m_available; }
    QStringList layouts() const { return m_layouts; }
    QStringList descriptions() const;
    QStringList shortNames() const { return m_shortNames; }
    QString switchOption() const { return m_switchOption; }
    QVariantList switchOptions() const;

    // Layouts not in use whose name or code contains `text`: [{ id, description }]
    Q_INVOKABLE QVariantList search(const QString &text) const;

    Q_INVOKABLE void add(const QString &id);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void move(int from, int to);
    Q_INVOKABLE void setSwitchOption(const QString &option);

signals:
    void changed();

private slots:
    void reload();

private:
    void loadCatalog();
    void save(const QStringList &layouts);

private:
    QDBusInterface m_iface;
    bool m_available = false;
    QStringList m_layouts;
    QStringList m_shortNames;
    QString m_switchOption;

    // id -> description, in xkeyboard-config order
    QStringList m_catalogIds;
    QHash<QString, QString> m_catalog;
};

#endif // KEYBOARDLAYOUTS_H
