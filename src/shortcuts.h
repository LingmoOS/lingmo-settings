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

#ifndef SHORTCUTS_H
#define SHORTCUTS_H

#include <QAbstractListModel>

class QFileSystemWatcher;

// Global keyboard shortcuts run by lingmo-chotkeys: one group per key sequence in
// ~/.config/lingmoglobalshortcutsrc (Comment=, Exec=). lingmo-chotkeys watches the
// file, so changes apply right away.
class Shortcuts : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        SequenceRole = Qt::UserRole + 1,   // portable form stored in the file ("Meta+Space")
        KeysRole,                          // as shown to the user
        NameRole,
        CommandRole,
    };

    explicit Shortcuts(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Key press from QML (event.key, event.modifiers) to a sequence; empty for a lone
    // modifier (the page handles a Meta tap on its own)
    Q_INVOKABLE QString sequenceFromKey(int key, int modifiers) const;
    Q_INVOKABLE QString displayText(const QString &sequence) const;

    // Name of the shortcut already using the sequence, or empty
    Q_INVOKABLE QString usedBy(const QString &sequence, const QString &ignoreSequence = QString()) const;

    // Adds, or replaces the shortcut at oldSequence. Returns an error message, empty on success.
    Q_INVOKABLE QString save(const QString &oldSequence, const QString &sequence,
                             const QString &name, const QString &command);
    Q_INVOKABLE void remove(const QString &sequence);

private:
    struct Entry {
        QString sequence;
        QString name;
        QString command;
    };

    QString configFile() const;
    void load();

    QList<Entry> m_entries;
    QFileSystemWatcher *m_watcher;
};

#endif // SHORTCUTS_H
