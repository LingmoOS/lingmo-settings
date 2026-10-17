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

#include "shortcuts.h"

#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QKeySequence>
#include <QSettings>
#include <QStandardPaths>

Shortcuts::Shortcuts(QObject *parent)
    : QAbstractListModel(parent)
    , m_watcher(new QFileSystemWatcher(this))
{
    load();

    // Other writers (lingmo-chotkeys defaults, the status bar's Spotlight menu)
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this] {
        load();
    });
}

QString Shortcuts::configFile() const
{
    return QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/lingmoglobalshortcutsrc";
}

void Shortcuts::load()
{
    beginResetModel();
    m_entries.clear();

    QSettings settings(configFile(), QSettings::IniFormat);
    for (const QString &group : settings.childGroups()) {
        settings.beginGroup(group);
        m_entries.append({group, settings.value("Comment").toString(), settings.value("Exec").toString()});
        settings.endGroup();
    }
    std::sort(m_entries.begin(), m_entries.end(), [](const Entry &a, const Entry &b) {
        return QString::localeAwareCompare(a.name, b.name) < 0;
    });
    endResetModel();

    // Saving replaces the file, which drops it from the watcher
    if (QFileInfo::exists(configFile()) && !m_watcher->files().contains(configFile()))
        m_watcher->addPath(configFile());
}

int Shortcuts::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant Shortcuts::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_entries.size())
        return {};

    const Entry &entry = m_entries.at(index.row());
    switch (role) {
    case SequenceRole:
        return entry.sequence;
    case KeysRole:
        return displayText(entry.sequence);
    case NameRole:
        return entry.name.isEmpty() ? entry.command : entry.name;
    case CommandRole:
        return entry.command;
    }
    return {};
}

QHash<int, QByteArray> Shortcuts::roleNames() const
{
    return {
        {SequenceRole, "sequence"},
        {KeysRole, "keys"},
        {NameRole, "name"},
        {CommandRole, "command"},
    };
}

QString Shortcuts::sequenceFromKey(int key, int modifiers) const
{
    switch (key) {
    case Qt::Key_Control: case Qt::Key_Shift: case Qt::Key_Alt:
    case Qt::Key_Super_L: case Qt::Key_Super_R: case Qt::Key_AltGr:
    case Qt::Key_Meta: case 0: case Qt::Key_unknown:
        return {};
    }
    const QKeyCombination combo(Qt::KeyboardModifiers(modifiers) & ~Qt::KeypadModifier, Qt::Key(key));
    return QKeySequence(combo).toString(QKeySequence::PortableText);
}

QString Shortcuts::displayText(const QString &sequence) const
{
    // "Meta" reads better as the key users know
    QString text = QKeySequence(sequence, QKeySequence::PortableText).toString(QKeySequence::NativeText);
    if (text.isEmpty())
        text = sequence;
    return text.replace(QLatin1String("Meta"), QLatin1String("Super"));
}

QString Shortcuts::usedBy(const QString &sequence, const QString &ignoreSequence) const
{
    for (const Entry &entry : m_entries) {
        if (entry.sequence == sequence && entry.sequence != ignoreSequence)
            return entry.name.isEmpty() ? entry.command : entry.name;
    }
    return {};
}

QString Shortcuts::save(const QString &oldSequence, const QString &sequence,
                        const QString &name, const QString &command)
{
    if (sequence.isEmpty())
        return tr("Press the keys for the shortcut");
    if (command.trimmed().isEmpty())
        return tr("Enter the command to run");
    const QString owner = usedBy(sequence, oldSequence);
    if (!owner.isEmpty())
        return tr("%1 is already used by \"%2\"").arg(displayText(sequence), owner);

    QSettings settings(configFile(), QSettings::IniFormat);
    if (!oldSequence.isEmpty() && oldSequence != sequence)
        settings.remove(oldSequence);
    settings.beginGroup(sequence);
    settings.setValue("Comment", name.trimmed().isEmpty() ? command.trimmed() : name.trimmed());
    settings.setValue("Exec", command.trimmed());
    settings.endGroup();
    settings.sync();

    load();
    return {};
}

void Shortcuts::remove(const QString &sequence)
{
    QSettings settings(configFile(), QSettings::IniFormat);
    settings.remove(sequence);
    settings.sync();
    load();
}
