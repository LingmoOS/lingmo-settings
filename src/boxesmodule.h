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

#pragma once

#include <QHash>
#include <QJsonObject>
#include <QObject>
#include <QUrl>
#include <QVariantList>

class QFileSystemWatcher;
class QTimer;

// The isolated boxes made by lingmo-winrun for programs from outside the
// Arch repositories (Windows, .deb/.rpm, AppImage, Android). The boxes are
// read from their descriptions (~/.config/lingmoos/boxes/<id>.json, format in
// lingmo-winrun's docs/boxes.md); changes and deletions go through
// `lingmo-winrun --box-set/--box-delete`, which knows how to apply them to
// bubblewrap, Podman, Flatpak and Waydroid. A QML singleton, so a change in
// progress (recreating a Linux box takes a while) survives page changes.
class BoxesModule : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList boxes READ boxes NOTIFY boxesChanged)
    Q_PROPERTY(bool winrunInstalled READ winrunInstalled NOTIFY boxesChanged)
    // The box being changed or deleted ("" when none)
    Q_PROPERTY(QString busyBox READ busyBox NOTIFY busyChanged)
    Q_PROPERTY(QString errorBox READ errorBox NOTIFY busyChanged)
    Q_PROPERTY(QString errorText READ errorText NOTIFY busyChanged)
    Q_PROPERTY(QString homePath READ homePath CONSTANT)

public:
    explicit BoxesModule(QObject *parent = nullptr);

    QVariantList boxes() const { return m_boxes; }
    bool winrunInstalled() const;
    QString busyBox() const { return m_busyBox; }
    QString errorBox() const { return m_errorBox; }
    QString errorText() const { return m_errorText; }
    QString homePath() const;

    Q_INVOKABLE void refresh();
    // key: files (none|personal), network, camera, microphone (on|off)
    Q_INVOKABLE void setPermission(const QString &boxId, const QString &key, const QString &value);
    Q_INVOKABLE void addFolder(const QString &boxId, const QUrl &folder);
    Q_INVOKABLE void removeFolder(const QString &boxId, const QString &folder);
    Q_INVOKABLE void deleteBox(const QString &boxId);
    Q_INVOKABLE void openFolder(const QString &path);
    Q_INVOKABLE void clearError();

    // Pure helpers, public for reuse
    static QString configDir();
    static QString formatSize(qint64 bytes);
    // A box description as the QML page shows it
    QVariantMap describe(const QJsonObject &box) const;

signals:
    void boxesChanged();
    void busyChanged();

private:
    void run(const QString &boxId, const QStringList &args);
    void computeSizes();

    QVariantList m_boxes;
    QHash<QString, qint64> m_sizes;
    QString m_busyBox;
    QString m_errorBox;
    QString m_errorText;
    QFileSystemWatcher *m_watcher;
    QTimer *m_reload;
    bool m_sizing = false;
};
