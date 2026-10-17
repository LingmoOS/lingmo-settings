#include "background.h"
#include <QtConcurrent>
#include <QDesktopServices>
#include <QFileInfo>
#include <QStandardPaths>

static const QStringList s_imageFilters = {"*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG"};

static QVariantList getBackgroundPaths()
{
    QStringList list;
    QDirIterator it("/usr/share/backgrounds/lingmoos", s_imageFilters, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString bg = it.next();
        list.append(bg);
    }
    std::sort(list.begin(), list.end());
    // One entry per file: QVariantList{list} would be a single QStringList entry in Qt 6
    QVariantList paths;
    for (const QString &path : list)
        paths.append(path);
    return paths;
}

Background::Background(QObject *parent)
    : QObject(parent)
    , m_interface("com.lingmo.Settings",
                  "/Theme",
                  "com.lingmo.Theme",
                  QDBusConnection::sessionBus(), this)
    , m_customWatcher(new QFileSystemWatcher(this))
{
    // Pictures added or removed by hand show up right away
    QDir().mkpath(customFolder());
    m_customWatcher->addPath(customFolder());
    connect(m_customWatcher, &QFileSystemWatcher::directoryChanged, this, &Background::customBackgroundsChanged);

    if (m_interface.isValid()) {
        m_currentPath = m_interface.property("wallpaper").toString();

        QDBusConnection::sessionBus().connect(m_interface.service(),
                                              m_interface.path(),
                                              m_interface.interface(),
                                              "backgroundTypeChanged", this, SIGNAL(backgroundTypeChanged()));
        QDBusConnection::sessionBus().connect(m_interface.service(),
                                              m_interface.path(),
                                              m_interface.interface(),
                                              "backgroundColorChanged", this, SIGNAL(backgroundColorChanged()));
    }
}

QVariantList Background::backgrounds()
{
    QFuture<QVariantList> future = QtConcurrent::run(&getBackgroundPaths);
    QVariantList list = future.result();
    return list;
}

QString Background::currentBackgroundPath()
{
    return m_currentPath;
}

void Background::setBackground(QString path)
{
    if (m_currentPath != path && !path.isEmpty()) {
        m_currentPath = path;

        if (m_interface.isValid()) {
            m_interface.call("setWallpaper", path);
            emit backgroundChanged();
        }
    }
}

int Background::backgroundType()
{
    return m_interface.property("backgroundType").toInt();
}

void Background::setBackgroundType(int type)
{
    m_interface.call("setBackgroundType", QVariant::fromValue(type));
}

QString Background::backgroundColor()
{
    return m_interface.property("backgroundColor").toString();
}

void Background::setBackgroundColor(const QString &color)
{
    m_interface.call("setBackgroundColor", QVariant::fromValue(color));
}

QString Background::customFolder() const
{
    return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/Wallpapers";
}

QVariantList Background::customBackgrounds() const
{
    QVariantList paths;
    const QFileInfoList files = QDir(customFolder()).entryInfoList(s_imageFilters, QDir::Files, QDir::Name | QDir::IgnoreCase);
    for (const QFileInfo &file : files)
        paths.append(file.absoluteFilePath());
    return paths;
}

bool Background::isCustomBackground(const QString &path) const
{
    return QFileInfo(path).absolutePath() == QDir(customFolder()).absolutePath();
}

int Background::addCustomBackgrounds(const QList<QUrl> &files)
{
    QDir folder(customFolder());
    folder.mkpath(".");

    QString last;
    int added = 0;
    for (const QUrl &url : files) {
        const QFileInfo source(url.isLocalFile() ? url.toLocalFile() : url.toString());
        if (!source.isFile())
            continue;

        QString target = folder.filePath(source.fileName());
        if (source.absoluteFilePath() != QFileInfo(target).absoluteFilePath()) {
            // Keep both when a different picture has the same name
            for (int n = 2; QFileInfo::exists(target); ++n)
                target = folder.filePath(QString("%1-%2.%3").arg(source.completeBaseName()).arg(n).arg(source.suffix()));
            if (!QFile::copy(source.absoluteFilePath(), target))
                continue;
        }
        last = target;
        ++added;
    }

    if (!last.isEmpty()) {
        setBackgroundType(0);
        setBackground(last);
    }
    emit customBackgroundsChanged();
    return added;
}

void Background::removeCustomBackground(const QString &path)
{
    if (!isCustomBackground(path))
        return;
    if (!QFile::moveToTrash(path))
        QFile::remove(path);
    emit customBackgroundsChanged();
}

void Background::openCustomFolder()
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(customFolder()));
}
