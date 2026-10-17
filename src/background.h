#ifndef BACKGROUND_H
#define BACKGROUND_H

#include <QObject>
#include <QList>
#include <QVariant>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QDirIterator>
#include <QDir>
#include <QFileSystemWatcher>
#include <QUrl>

class Background : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentBackgroundPath READ currentBackgroundPath WRITE setBackground NOTIFY backgroundChanged)
    Q_PROPERTY(QVariantList backgrounds READ backgrounds NOTIFY stub)

    Q_PROPERTY(int backgroundType READ backgroundType WRITE setBackgroundType NOTIFY backgroundTypeChanged)
    Q_PROPERTY(QString backgroundColor READ backgroundColor WRITE setBackgroundColor NOTIFY backgroundColorChanged)

    // The user's own wallpapers: every image in customFolder (~/Pictures/Wallpapers)
    Q_PROPERTY(QString customFolder READ customFolder CONSTANT)
    Q_PROPERTY(QVariantList customBackgrounds READ customBackgrounds NOTIFY customBackgroundsChanged)

public:
    explicit Background(QObject *parent = nullptr);

    QVariantList backgrounds();
    QString currentBackgroundPath();
    Q_INVOKABLE void setBackground(QString newBackgroundPath);

    int backgroundType();
    void setBackgroundType(int type);

    QString backgroundColor();
    void setBackgroundColor(const QString &color);

    QString customFolder() const;
    QVariantList customBackgrounds() const;
    // Copies the picked files into customFolder and makes the last one the wallpaper
    Q_INVOKABLE int addCustomBackgrounds(const QList<QUrl> &files);
    // Moves the image to the trash
    Q_INVOKABLE void removeCustomBackground(const QString &path);
    Q_INVOKABLE void openCustomFolder();
    Q_INVOKABLE bool isCustomBackground(const QString &path) const;

signals:
    void backgroundChanged();
    void backgroundColorChanged();
    void backgroundTypeChanged();
    void stub();
    void customBackgroundsChanged();

private:
    QDBusInterface m_interface;
    QString m_currentPath;
    QFileSystemWatcher *m_customWatcher;
};

#endif
