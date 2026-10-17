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

#ifndef AUTOSTART_H
#define AUTOSTART_H

#include <QAbstractListModel>
#include <QVariantList>

class QFileSystemWatcher;

// Apps started at login: the XDG autostart entries lingmo-session runs. The user
// directory (~/.config/autostart) overrides system entries with the same file name;
// turning an entry off writes Hidden=true into the user copy.
class Autostart : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QVariantList applications READ applications CONSTANT)

public:
    enum Roles {
        FileNameRole = Qt::UserRole + 1,
        NameRole,
        CommentRole,
        IconRole,
        CommandRole,
        EnabledRole,
        RemovableRole,   // only in the user directory: can be deleted
    };

    explicit Autostart(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Installed apps for the "add" picker: [{name, icon, path}], sorted by name
    QVariantList applications() const;

    Q_INVOKABLE void setEnabled(const QString &fileName, bool enabled);
    Q_INVOKABLE bool addApplication(const QString &desktopFile);
    Q_INVOKABLE QString addCommand(const QString &name, const QString &command);
    Q_INVOKABLE void remove(const QString &fileName);

private:
    struct Entry {
        QString fileName;
        QString path;
        QString name;
        QString comment;
        QString icon;
        QString command;
        bool enabled = true;
        bool inUserDir = false;
        bool inSystemDir = false;
    };

    QString userDir() const;
    void load();
    // Copies the effective entry into the user directory so it can be changed
    QString userCopy(const QString &fileName);

    QList<Entry> m_entries;
    QFileSystemWatcher *m_watcher;
};

#endif // AUTOSTART_H
