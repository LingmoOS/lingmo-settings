/*
 * Copyright (C) 2026 LingmoOS Team.
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

#include "boxesmodule.h"

#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QFutureWatcher>
#include <QJsonArray>
#include <QJsonDocument>
#include <QLocale>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>
#include <QtConcurrent>

namespace {

qint64 folderSize(const QString &path)
{
    const QFileInfo info(path);
    if (info.isSymLink())
        return 0;
    if (info.isFile())
        return info.size();
    qint64 total = 0;
    QDirIterator it(path, QDir::Files | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        const QFileInfo f = it.fileInfo();
        if (!f.isSymLink())
            total += f.size();
    }
    return total;
}

// "/home/ana/Boxes/Windows" -> "~/Boxes/Windows"
QString tilde(const QString &path)
{
    const QString home = QDir::homePath();
    return path.startsWith(home + QLatin1Char('/')) ? QLatin1Char('~') + path.mid(home.size()) : path;
}

} // namespace

BoxesModule::BoxesModule(QObject *parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_reload(new QTimer(this))
{
    // Several files change at once when a box is installed: reload once
    m_reload->setSingleShot(true);
    m_reload->setInterval(300);
    connect(m_reload, &QTimer::timeout, this, &BoxesModule::refresh);
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, m_reload, qOverload<>(&QTimer::start));
    connect(m_watcher, &QFileSystemWatcher::fileChanged, m_reload, qOverload<>(&QTimer::start));
    refresh();
}

QString BoxesModule::configDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/lingmoos/boxes");
}

QString BoxesModule::homePath() const
{
    return QDir::homePath();
}

bool BoxesModule::winrunInstalled() const
{
    return !QStandardPaths::findExecutable(QStringLiteral("lingmo-winrun")).isEmpty();
}

QString BoxesModule::formatSize(qint64 bytes)
{
    if (bytes < 0)
        return QString();
    return QLocale().formattedDataSize(bytes, 1, QLocale::DataSizeTraditionalFormat);
}

QVariantMap BoxesModule::describe(const QJsonObject &o) const
{
    const QString id = o.value(QStringLiteral("id")).toString();
    const QString type = o.value(QStringLiteral("type")).toString();
    QVariantMap m;
    m[QStringLiteral("id")] = id;
    m[QStringLiteral("type")] = type;

    // Names in the current language for the shared boxes; an AppImage box is named after its program
    QString name = o.value(QStringLiteral("name")).toString();
    QString typeLabel;
    QString icon;
    if (type == QLatin1String("container")) {
        const bool fedora = o.value(QStringLiteral("distro")).toString() == QLatin1String("fedora");
        name = tr("Linux programs (%1)").arg(fedora ? QStringLiteral("Fedora") : QStringLiteral("Ubuntu"));
        typeLabel = tr("Linux box, for .deb and .rpm packages");
        icon = fedora ? QStringLiteral("application-x-rpm") : QStringLiteral("application-vnd.debian.binary-package");
    } else if (type == QLatin1String("bottles")) {
        name = tr("Windows programs");
        typeLabel = tr("Windows box (Bottles)");
        icon = QStringLiteral("wine");
    } else if (type == QLatin1String("android")) {
        name = tr("Android apps");
        typeLabel = tr("Android box (Waydroid)");
        icon = QStringLiteral("application-vnd.android.package-archive");
    } else if (type == QLatin1String("appimage")) {
        typeLabel = tr("AppImage box");
        icon = o.value(QStringLiteral("icon")).toString();
        if (icon.isEmpty() || !QFileInfo::exists(icon))
            icon = QStringLiteral("application-vnd.appimage");
        else
            icon = QUrl::fromLocalFile(icon).toString();
    } else {
        typeLabel = tr("Box");
        icon = QStringLiteral("package-x-generic");
    }
    m[QStringLiteral("name")] = name.isEmpty() ? id : name;
    m[QStringLiteral("typeLabel")] = typeLabel;
    m[QStringLiteral("icon")] = icon;

    QVariantList apps;
    for (const QJsonValue &v : o.value(QStringLiteral("apps")).toArray()) {
        const QJsonObject a = v.toObject();
        apps.append(QVariantMap{{QStringLiteral("name"), a.value(QStringLiteral("name")).toString()},
                                {QStringLiteral("version"), a.value(QStringLiteral("version")).toString()}});
    }
    m[QStringLiteral("apps")] = apps;

    const bool changeable = type == QLatin1String("appimage") || type == QLatin1String("container") || type == QLatin1String("bottles");
    m[QStringLiteral("changeable")] = changeable;
    m[QStringLiteral("files")] = o.value(QStringLiteral("files")).toString(QStringLiteral("none"));
    QStringList folders;
    for (const QJsonValue &v : o.value(QStringLiteral("folders")).toArray())
        folders << v.toString();
    m[QStringLiteral("folders")] = folders;
    m[QStringLiteral("network")] = o.value(QStringLiteral("network")).toBool(true);
    m[QStringLiteral("camera")] = o.value(QStringLiteral("camera")).toBool(false);
    m[QStringLiteral("microphone")] = o.value(QStringLiteral("microphone")).toBool(true);
    m[QStringLiteral("exchange")] = o.value(QStringLiteral("exchange")).toString();
    m[QStringLiteral("home")] = o.value(QStringLiteral("home")).toString();

    // When a change applies (docs/boxes.md)
    QString applies;
    if (type == QLatin1String("appimage"))
        applies = tr("Changes apply the next time the program starts.");
    else if (type == QLatin1String("container"))
        applies = tr("Changing these restarts the box: programs open in it close. Installed programs and their files stay.");
    else if (type == QLatin1String("bottles"))
        applies = tr("Changes apply the next time Bottles starts. Bottles has one set of permissions, so they also apply to bottles you made in Bottles yourself.");
    else if (type == QLatin1String("android"))
        applies = tr("Waydroid sets these for all Android apps and they can't be changed here: Android sees none of your folders, uses the network and plays sound, and has no camera.");
    m[QStringLiteral("applies")] = applies;

    // What deleting it removes
    QString deletes;
    if (type == QLatin1String("appimage"))
        deletes = tr("The program, its settings and the files it saved in its box will be deleted.");
    else if (type == QLatin1String("container"))
        deletes = tr("Every program installed in this box and its home folder (%1) will be deleted.").arg(tilde(m.value(QStringLiteral("home")).toString()));
    else if (type == QLatin1String("bottles"))
        deletes = tr("Every Windows program installed from Lingmo and its settings will be deleted. Your files in %1 stay.").arg(tilde(m.value(QStringLiteral("exchange")).toString()));
    else if (type == QLatin1String("android"))
        deletes = tr("Every Android app installed from Lingmo and its data will be deleted. Android itself stays installed.");
    m[QStringLiteral("deletes")] = deletes;

    const qint64 size = m_sizes.value(id, -1);
    m[QStringLiteral("size")] = size;
    m[QStringLiteral("sizeText")] = formatSize(size);
    QStringList storage;
    for (const QJsonValue &v : o.value(QStringLiteral("storage")).toArray())
        storage << v.toString();
    m[QStringLiteral("storage")] = storage;
    return m;
}

void BoxesModule::refresh()
{
    const QString dir = configDir();
    QDir().mkpath(dir);
    if (!m_watcher->directories().contains(dir))
        m_watcher->addPath(dir);
    if (!m_watcher->files().isEmpty())
        m_watcher->removePaths(m_watcher->files());

    QVariantList list;
    const QDir d(dir);
    for (const QString &file : d.entryList({QStringLiteral("*.json")}, QDir::Files, QDir::Name)) {
        QFile f(d.filePath(file));
        if (!f.open(QIODevice::ReadOnly) || f.size() > 4 * 1024 * 1024)
            continue;
        const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
        if (o.value(QStringLiteral("id")).toString() + QStringLiteral(".json") != file)
            continue;
        m_watcher->addPath(d.filePath(file));
        list.append(describe(o));
    }
    // Shared boxes first (Windows, Linux, Android), then the AppImages by name
    std::stable_sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        auto rank = [](const QVariantMap &m) {
            static const QStringList order = {QStringLiteral("bottles"), QStringLiteral("container"), QStringLiteral("android")};
            const int i = order.indexOf(m.value(QStringLiteral("type")).toString());
            return i < 0 ? order.size() : i;
        };
        const QVariantMap ma = a.toMap(), mb = b.toMap();
        if (rank(ma) != rank(mb))
            return rank(ma) < rank(mb);
        return ma.value(QStringLiteral("name")).toString().localeAwareCompare(mb.value(QStringLiteral("name")).toString()) < 0;
    });
    m_boxes = list;
    emit boxesChanged();
    computeSizes();
}

void BoxesModule::computeSizes()
{
    if (m_sizing)
        return;
    QHash<QString, QStringList> storage;
    for (const QVariant &v : std::as_const(m_boxes)) {
        const QVariantMap m = v.toMap();
        storage.insert(m.value(QStringLiteral("id")).toString(), m.value(QStringLiteral("storage")).toStringList());
    }
    m_sizing = true;
    auto *watcher = new QFutureWatcher<QHash<QString, qint64>>(this);
    connect(watcher, &QFutureWatcherBase::finished, this, [this, watcher] {
        m_sizes = watcher->result();
        watcher->deleteLater();
        m_sizing = false;
        for (QVariant &v : m_boxes) {
            QVariantMap m = v.toMap();
            const qint64 size = m_sizes.value(m.value(QStringLiteral("id")).toString(), -1);
            m[QStringLiteral("size")] = size;
            m[QStringLiteral("sizeText")] = formatSize(size);
            v = m;
        }
        emit boxesChanged();
    });
    watcher->setFuture(QtConcurrent::run([storage] {
        QHash<QString, qint64> sizes;
        for (auto it = storage.cbegin(); it != storage.cend(); ++it) {
            qint64 total = 0;
            for (const QString &path : it.value())
                total += folderSize(path);
            sizes.insert(it.key(), total);
        }
        return sizes;
    }));
}

void BoxesModule::run(const QString &boxId, const QStringList &args)
{
    if (!m_busyBox.isEmpty())
        return;
    if (!winrunInstalled()) {
        m_errorBox = boxId;
        m_errorText = tr("Lingmo Install Programs (lingmo-winrun) is not installed.");
        emit busyChanged();
        return;
    }
    m_busyBox = boxId;
    m_errorBox.clear();
    m_errorText.clear();
    emit busyChanged();
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p, boxId](int code, QProcess::ExitStatus status) {
        const QString err = QString::fromLocal8Bit(p->readAllStandardError()).trimmed();
        p->deleteLater();
        m_busyBox.clear();
        if (status != QProcess::NormalExit || code != 0) {
            m_errorBox = boxId;
            m_errorText = err.isEmpty() ? tr("The change could not be made.") : err.section(QLatin1Char('\n'), -3);
        }
        emit busyChanged();
        refresh();
    });
    connect(p, &QProcess::errorOccurred, this, [this, p, boxId](QProcess::ProcessError e) {
        if (e != QProcess::FailedToStart)
            return;
        p->deleteLater();
        m_busyBox.clear();
        m_errorBox = boxId;
        m_errorText = tr("Lingmo Install Programs (lingmo-winrun) is not installed.");
        emit busyChanged();
    });
    p->start(QStringLiteral("lingmo-winrun"), args);
}

void BoxesModule::setPermission(const QString &boxId, const QString &key, const QString &value)
{
    static const QStringList keys = {QStringLiteral("files"), QStringLiteral("network"), QStringLiteral("camera"), QStringLiteral("microphone")};
    if (!keys.contains(key))
        return;
    run(boxId, {QStringLiteral("--box-set"), boxId, key, value});
}

void BoxesModule::addFolder(const QString &boxId, const QUrl &folder)
{
    const QString path = folder.isLocalFile() ? folder.toLocalFile() : folder.toString();
    if (!path.isEmpty())
        run(boxId, {QStringLiteral("--box-set"), boxId, QStringLiteral("folder-add"), path});
}

void BoxesModule::removeFolder(const QString &boxId, const QString &folder)
{
    run(boxId, {QStringLiteral("--box-set"), boxId, QStringLiteral("folder-remove"), folder});
}

void BoxesModule::deleteBox(const QString &boxId)
{
    run(boxId, {QStringLiteral("--box-delete"), boxId});
}

void BoxesModule::openFolder(const QString &path)
{
    if (!path.isEmpty() && QFileInfo(path).isDir())
        QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void BoxesModule::clearError()
{
    if (m_errorText.isEmpty())
        return;
    m_errorBox.clear();
    m_errorText.clear();
    emit busyChanged();
}
