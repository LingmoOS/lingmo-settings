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

#include <QElapsedTimer>
#include <QHash>
#include <QObject>
#include <QPointer>
#include <QStringList>
#include <QUrl>
#include <QVariantList>

class QNetworkAccessManager;
class QNetworkReply;
class QProcess;
class QTimer;

// The system-wide AI settings (~/.config/lingmoos/ai.conf, read by Spotlight
// and Automator), the local Ollama server and llmfit's hardware-aware
// recommendations. A QML singleton, so a download keeps going while the user
// visits other pages.
class AIModule : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString provider READ provider NOTIFY configChanged)
    Q_PROPERTY(QString model READ model NOTIFY configChanged)
    Q_PROPERTY(bool modelInstalled READ modelInstalled NOTIFY installedModelsChanged)

    Q_PROPERTY(int ollamaState READ ollamaState NOTIFY ollamaChanged)
    Q_PROPERTY(QString ollamaVersion READ ollamaVersion NOTIFY ollamaChanged)
    Q_PROPERTY(bool canStartOllama READ canStartOllama NOTIFY ollamaChanged)
    Q_PROPERTY(bool serviceActive READ serviceActive NOTIFY ollamaChanged)
    Q_PROPERTY(bool remoteServer READ remoteServer CONSTANT)
    Q_PROPERTY(QString serverAddress READ serverAddress CONSTANT)
    Q_PROPERTY(QVariantList installedModels READ installedModels NOTIFY installedModelsChanged)

    Q_PROPERTY(bool llmfitAvailable READ llmfitAvailable NOTIFY llmfitChanged)
    Q_PROPERTY(bool llmfitBusy READ llmfitBusy NOTIFY llmfitChanged)
    Q_PROPERTY(QString llmfitError READ llmfitError NOTIFY llmfitChanged)
    Q_PROPERTY(QString systemSummary READ systemSummary NOTIFY llmfitChanged)
    Q_PROPERTY(QString useCase READ useCase WRITE setUseCase NOTIFY useCaseChanged)
    Q_PROPERTY(QVariantList recommendations READ recommendations NOTIFY recommendationsChanged)

    Q_PROPERTY(bool pulling READ pulling NOTIFY pullChanged)
    Q_PROPERTY(QString pullModel READ pullModel NOTIFY pullChanged)
    Q_PROPERTY(qreal pullProgress READ pullProgress NOTIFY pullChanged)
    Q_PROPERTY(QString pullDetail READ pullDetail NOTIFY pullChanged)

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString errorText READ errorText NOTIFY messageChanged)
    Q_PROPERTY(QString infoText READ infoText NOTIFY messageChanged)

public:
    enum OllamaState {
        Checking = 0,
        NotInstalled,
        Stopped,
        Starting,
        Running
    };
    Q_ENUM(OllamaState)

    explicit AIModule(QObject *parent = nullptr);

    QString provider() const { return m_provider; }
    QString model() const { return m_model; }
    bool modelInstalled() const;

    int ollamaState() const { return m_ollamaState; }
    QString ollamaVersion() const { return m_ollamaVersion; }
    bool canStartOllama() const;
    bool serviceActive() const { return m_serviceActive; }
    bool remoteServer() const;
    QString serverAddress() const;
    QVariantList installedModels() const;

    bool llmfitAvailable() const;
    bool llmfitBusy() const { return m_llmfitProcess != nullptr || m_llmfitParsing; }
    QString llmfitError() const { return m_llmfitError; }
    QString systemSummary() const { return m_systemSummary; }
    QString useCase() const { return m_useCase; }
    void setUseCase(const QString &useCase);
    QVariantList recommendations() const;

    bool pulling() const { return m_pullReply != nullptr; }
    QString pullModel() const { return m_pullModel; }
    qreal pullProgress() const { return m_pullProgress; }
    QString pullDetail() const { return m_pullDetail; }

    bool busy() const { return m_busy > 0; }
    QString errorText() const { return m_errorText; }
    QString infoText() const { return m_infoText; }

    // Refreshes the Ollama status and the installed models; starts llmfit once per session
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void loadRecommendations();
    Q_INVOKABLE void refreshRecommendations();
    Q_INVOKABLE void setDefaultModel(const QString &name);
    Q_INVOKABLE void startOllama();
    Q_INVOKABLE bool isValidModelName(const QString &name) const;
    Q_INVOKABLE void pull(const QString &name);
    Q_INVOKABLE void cancelPull();
    Q_INVOKABLE void removeModel(const QString &name);
    Q_INVOKABLE void clearMessages();

signals:
    void configChanged();
    void ollamaChanged();
    void installedModelsChanged();
    void llmfitChanged();
    void useCaseChanged();
    void recommendationsChanged();
    void pullChanged();
    void busyChanged();
    void messageChanged();

private:
    struct Installed {
        QString name;
        QString parameterSize;
        QString quantization;
        qint64 size = 0;
        bool embedding = false;
    };

    struct FitInfo {
        QString ollamaName;
        QString fitLevel;
        QString runMode;
        double score = 0;
        double tps = 0;
        double diskGb = 0;
        double memoryGb = 0;
        QString parameters;
    };

    struct LlmfitResult {
        bool ok = false;
        QString error;
        QString systemSummary;
        QList<FitInfo> models; // ollama-usable only, best score first, one per name
    };

    struct LlmfitJob {
        QString kind; // "fit" or a use case
        QStringList arguments;
    };

    void loadConfig();
    void writeConfig(const QString &provider, const QString &model);
    QUrl apiUrl(const QString &path) const;
    void setOllamaState(int state);
    void checkVersion();
    void checkInstallation();
    void fetchTags();
    void setError(const QString &text);
    void setInfo(const QString &text);
    void changeBusy(int delta);

    void queueLlmfit(const QString &kind);
    void runNextLlmfit();
    void llmfitFinished(const QString &kind, const LlmfitResult &result);
    static LlmfitResult parseLlmfit(const QByteArray &json);
    QVariantMap fitToMap(const FitInfo &fit) const;
    QString fitText(const QString &level) const;
    QString runModeText(const QString &mode) const;

    void readPullData();
    void finishPull();
    void updatePullDetail();

    static QString normalizedName(const QString &name);
    QString formatGb(double gb) const;

    QNetworkAccessManager *m_network;
    QTimer *m_pollTimer;

    QString m_provider;
    QString m_model;

    int m_ollamaState = Checking;
    QString m_ollamaVersion;
    QString m_ollamaBinary;
    bool m_hasService = false;
    bool m_serviceActive = false; // systemd says it runs, yet the API doesn't answer
    QList<Installed> m_installed;
    int m_startAttempts = 0;

    QString m_useCase = QStringLiteral("chat");
    QHash<QString, QList<FitInfo>> m_recommendations; // per use case, cached for the session
    QHash<QString, FitInfo> m_fitByName;              // every ollama model llmfit knows
    bool m_fitLoaded = false;
    QList<LlmfitJob> m_llmfitQueue;
    QPointer<QProcess> m_llmfitProcess;
    bool m_llmfitParsing = false;
    QString m_llmfitError;
    QString m_systemSummary;
    bool m_llmfitMissing = false;

    QPointer<QNetworkReply> m_pullReply;
    QString m_pullModel;
    QByteArray m_pullBuffer;
    QHash<QString, QPair<qint64, qint64>> m_pullLayers; // digest -> completed, total
    QString m_pullStatus;
    qreal m_pullProgress = -1;
    QString m_pullDetail;
    QString m_pullFailure;
    bool m_pullSucceeded = false;
    bool m_pullCancelled = false;
    QElapsedTimer m_speedTimer;
    qint64 m_speedBytes = 0;
    double m_speed = 0;

    int m_busy = 0;
    QString m_errorText;
    QString m_infoText;
};
