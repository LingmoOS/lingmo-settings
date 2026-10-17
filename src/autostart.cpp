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

#include "autostart.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QLocale>
#include <QRegularExpression>
#include <QSet>
#include <QStandardPaths>

// Desktop entries are read and written as text: QSettings treats ';' as a comment
// and would rewrite the file in its own escaping
namespace {

QMap<QString, QString> readEntry(const QString &path)
{
    QMap<QString, QString> keys;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return keys;

    bool inMain = false;
    while (!file.atEnd()) {
        const QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (line.startsWith(QLatin1Char('['))) {
            inMain = line == QLatin1String("[Desktop Entry]");
            continue;
        }
        const int eq = line.indexOf(QLatin1Char('='));
        if (inMain && eq > 0 && !line.startsWith(QLatin1Char('#')))
            keys.insert(line.left(eq).trimmed(), line.mid(eq + 1).trimmed());
    }
    return keys;
}

QString localized(const QMap<QString, QString> &keys, const QString &key)
{
    const QLocale locale;
    for (const QString &suffix : {locale.name(), locale.name().section(QLatin1Char('_'), 0, 0)}) {
        const QString value = keys.value(QStringLiteral("%1[%2]").arg(key, suffix));
        if (!value.isEmpty())
            return value;
    }
    return keys.value(key);
}

// Sets key=value in the [Desktop Entry] group, keeping everything else as is
bool writeKey(const QString &path, const QString &key, const QString &value)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;
    QStringList lines = QString::fromUtf8(file.readAll()).split(QLatin1Char('\n'));
    file.close();

    int groupStart = -1, groupEnd = lines.size();
    for (int i = 0; i < lines.size(); ++i) {
        const QString line = lines.at(i).trimmed();
        if (line.startsWith(QLatin1Char('['))) {
            if (groupStart >= 0) {
                groupEnd = i;
                break;
            }
            if (line == QLatin1String("[Desktop Entry]"))
                groupStart = i;
        }
    }
    if (groupStart < 0) {
        lines.prepend(QStringLiteral("[Desktop Entry]"));
        groupStart = 0;
        groupEnd = 1;
    }

    bool replaced = false;
    for (int i = groupStart + 1; i < groupEnd; ++i) {
        if (lines.at(i).section(QLatin1Char('='), 0, 0).trimmed() == key) {
            lines[i] = key + QLatin1Char('=') + value;
            replaced = true;
            break;
        }
    }
    if (!replaced) {
        // After the group's last non-empty line
        int at = groupEnd;
        while (at > groupStart + 1 && lines.at(at - 1).trimmed().isEmpty())
            --at;
        lines.insert(at, key + QLatin1Char('=') + value);
    }

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
        return false;
    file.write(lines.join(QLatin1Char('\n')).toUtf8());
    return true;
}

bool shownInLingmo(const QMap<QString, QString> &keys)
{
    const auto list = [&](const QString &key) {
        return keys.value(key).split(QLatin1Char(';'), Qt::SkipEmptyParts);
    };
    if (list(QStringLiteral("NotShowIn")).contains(QLatin1String("Lingmo")))
        return false;
    const QStringList only = list(QStringLiteral("OnlyShowIn"));
    return only.isEmpty() || only.contains(QLatin1String("Lingmo"));
}

} // namespace

Autostart::Autostart(QObject *parent)
    : QAbstractListModel(parent)
    , m_watcher(new QFileSystemWatcher(this))
{
    QDir().mkpath(userDir());
    m_watcher->addPath(userDir());
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &Autostart::load);
    load();
}

QString Autostart::userDir() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/autostart";
}

void Autostart::load()
{
    beginResetModel();
    m_entries.clear();

    const QStringList dirs = QStandardPaths::locateAll(QStandardPaths::GenericConfigLocation,
                                                       QStringLiteral("autostart"),
                                                       QStandardPaths::LocateDirectory);
    const QString user = QDir(userDir()).canonicalPath();
    QHash<QString, int> index;

    for (const QString &dir : dirs) {
        const bool isUser = QDir(dir).canonicalPath() == user;
        const QFileInfoList files = QDir(dir).entryInfoList({QStringLiteral("*.desktop")}, QDir::Files);
        for (const QFileInfo &info : files) {
            if (index.contains(info.fileName())) {
                // A system file that the user copy overrides
                m_entries[index.value(info.fileName())].inSystemDir |= !isUser;
                continue;
            }

            const QMap<QString, QString> keys = readEntry(info.absoluteFilePath());
            if (!shownInLingmo(keys) || keys.value("Type", "Application") != QLatin1String("Application"))
                continue;

            Entry entry;
            entry.fileName = info.fileName();
            entry.path = info.absoluteFilePath();
            entry.name = localized(keys, "Name");
            if (entry.name.isEmpty())
                entry.name = info.completeBaseName();
            entry.comment = localized(keys, "Comment");
            entry.icon = keys.value("Icon");
            entry.command = keys.value("Exec");
            entry.enabled = keys.value("Hidden") != QLatin1String("true")
                            && keys.value("X-GNOME-Autostart-enabled") != QLatin1String("false");
            entry.inUserDir = isUser;
            entry.inSystemDir = !isUser;

            index.insert(entry.fileName, m_entries.size());
            m_entries.append(entry);
        }
    }

    std::sort(m_entries.begin(), m_entries.end(), [](const Entry &a, const Entry &b) {
        return QString::localeAwareCompare(a.name, b.name) < 0;
    });
    endResetModel();
}

int Autostart::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant Autostart::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_entries.size())
        return {};

    const Entry &entry = m_entries.at(index.row());
    switch (role) {
    case FileNameRole: return entry.fileName;
    case NameRole: return entry.name;
    case CommentRole: return entry.comment;
    case IconRole: return entry.icon;
    case CommandRole: return entry.command;
    case EnabledRole: return entry.enabled;
    case RemovableRole: return entry.inUserDir && !entry.inSystemDir;
    }
    return {};
}

QHash<int, QByteArray> Autostart::roleNames() const
{
    return {
        {FileNameRole, "fileName"},
        {NameRole, "name"},
        {CommentRole, "comment"},
        {IconRole, "iconName"},
        {CommandRole, "command"},
        {EnabledRole, "enabled"},
        {RemovableRole, "removable"},
    };
}

QString Autostart::userCopy(const QString &fileName)
{
    const QString target = userDir() + QLatin1Char('/') + fileName;
    if (QFileInfo::exists(target))
        return target;

    for (const Entry &entry : std::as_const(m_entries)) {
        if (entry.fileName == fileName) {
            QDir().mkpath(userDir());
            if (QFile::copy(entry.path, target)) {
                QFile(target).setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ReadGroup | QFile::ReadOther);
                return target;
            }
        }
    }
    return {};
}

void Autostart::setEnabled(const QString &fileName, bool enabled)
{
    const QString path = userCopy(fileName);
    if (path.isEmpty())
        return;

    writeKey(path, QStringLiteral("Hidden"), enabled ? QStringLiteral("false") : QStringLiteral("true"));
    // GNOME's switch, which some entries ship as false
    if (readEntry(path).contains(QStringLiteral("X-GNOME-Autostart-enabled")))
        writeKey(path, QStringLiteral("X-GNOME-Autostart-enabled"), enabled ? QStringLiteral("true") : QStringLiteral("false"));
    load();
}

bool Autostart::addApplication(const QString &desktopFile)
{
    const QFileInfo source(desktopFile);
    const QString target = userDir() + QLatin1Char('/') + source.fileName();
    QDir().mkpath(userDir());
    QFile::remove(target);
    if (!QFile::copy(source.absoluteFilePath(), target))
        return false;
    QFile(target).setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ReadGroup | QFile::ReadOther);
    writeKey(target, QStringLiteral("Hidden"), QStringLiteral("false"));
    load();
    return true;
}

QString Autostart::addCommand(const QString &name, const QString &command)
{
    if (command.trimmed().isEmpty())
        return tr("Enter the command to run");

    QString base = name.trimmed().isEmpty() ? command.trimmed().section(QLatin1Char(' '), 0, 0) : name.trimmed();
    base = QFileInfo(base).fileName().toLower().replace(QRegularExpression(QStringLiteral("[^a-z0-9._-]+")), QStringLiteral("-"));
    QString fileName = base + QStringLiteral(".desktop");
    for (int n = 2; QFileInfo::exists(userDir() + QLatin1Char('/') + fileName); ++n)
        fileName = QStringLiteral("%1-%2.desktop").arg(base).arg(n);

    QDir().mkpath(userDir());
    QFile file(userDir() + QLatin1Char('/') + fileName);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return tr("Could not create the entry");
    file.write(QStringLiteral("[Desktop Entry]\nType=Application\nName=%1\nExec=%2\nIcon=application-x-executable\n")
                   .arg(name.trimmed().isEmpty() ? command.trimmed() : name.trimmed(), command.trimmed())
                   .toUtf8());
    file.close();
    load();
    return {};
}

void Autostart::remove(const QString &fileName)
{
    const QString path = userDir() + QLatin1Char('/') + fileName;
    for (const Entry &entry : std::as_const(m_entries)) {
        // A system entry can only be turned off: deleting the user copy would bring it back on
        if (entry.fileName == fileName && entry.inSystemDir) {
            setEnabled(fileName, false);
            return;
        }
    }
    QFile::remove(path);
    load();
}

QVariantList Autostart::applications() const
{
    QVariantList apps;
    QSet<QString> seen;
    const QStringList dirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
    for (const QString &dir : dirs) {
        const QFileInfoList files = QDir(dir).entryInfoList({QStringLiteral("*.desktop")}, QDir::Files);
        for (const QFileInfo &info : files) {
            if (seen.contains(info.fileName()))
                continue;
            seen.insert(info.fileName());

            const QMap<QString, QString> keys = readEntry(info.absoluteFilePath());
            if (keys.value("NoDisplay") == QLatin1String("true") || keys.value("Hidden") == QLatin1String("true")
                || keys.value("Type") != QLatin1String("Application") || !shownInLingmo(keys))
                continue;

            QVariantMap app;
            app["name"] = localized(keys, "Name");
            app["icon"] = keys.value("Icon");
            app["path"] = info.absoluteFilePath();
            apps.append(app);
        }
    }
    std::sort(apps.begin(), apps.end(), [](const QVariant &a, const QVariant &b) {
        return QString::localeAwareCompare(a.toMap().value("name").toString(), b.toMap().value("name").toString()) < 0;
    });
    return apps;
}
