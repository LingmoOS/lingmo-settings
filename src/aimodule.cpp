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

#include "aimodule.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <QtConcurrent>

#include <algorithm>

namespace {

const QString ConfigOrganization = QStringLiteral("lingmoos");
const QString ConfigApplication = QStringLiteral("ai");
const QString LegacyGroup = QStringLiteral("ai");
constexpr int LlmfitTimeoutMs = 60000;
constexpr int ApiTimeoutMs = 4000;
constexpr int StartPolls = 10; // the page polls every few seconds

// docs/assistant-contract.md
const QString AssistantProgram = QStringLiteral("lingmo-assistant");
const QString KeyAssistantRead = QStringLiteral("assistant_read");
const QString KeyAssistantWrite = QStringLiteral("assistant_write");
const QString KeyAssistantTools = QStringLiteral("assistant_tools");
const QString KeyAssistantFolders = QStringLiteral("assistant_folders");

// Tools checked when assistant_tools is missing ("web" starts unchecked)
const QStringList DefaultAssistantTools = {
    QStringLiteral("system_info"), QStringLiteral("shell_read"), QStringLiteral("read_files"),
    QStringLiteral("search_files"), QStringLiteral("notes_read"), QStringLiteral("calendar_read"),
    QStringLiteral("notes_write"), QStringLiteral("calendar_write"), QStringLiteral("files_write"),
};

// Home-relative areas no tool may touch, even inside an allowed folder
const QStringList BlockedHomePaths = {
    QStringLiteral(".ssh"), QStringLiteral(".gnupg"), QStringLiteral(".password-store"),
    QStringLiteral(".local/share/keyrings"), QStringLiteral(".config/lingmo-online-accounts"),
    QStringLiteral(".pki"), QStringLiteral(".mozilla"), QStringLiteral(".thunderbird"),
    QStringLiteral(".config/google-chrome"), QStringLiteral(".config/chromium"),
    QStringLiteral(".config/BraveSoftware"), QStringLiteral(".netrc"), QStringLiteral(".aws"),
    QStringLiteral(".kube"), QStringLiteral(".docker/config.json"),
};
const QStringList BlockedFilePatterns = {
    QStringLiteral("*.kdbx"), QStringLiteral(".env"), QStringLiteral("id_*"),
    QStringLiteral("*.pem"), QStringLiteral("*.key"),
};

// Resolves symlinks when the path exists; otherwise just cleans it
QString resolvedPath(const QString &path)
{
    const QString canonical = QFileInfo(path).canonicalFilePath();
    return canonical.isEmpty() ? QDir::cleanPath(path) : canonical;
}

bool isSameOrInside(const QString &path, const QString &area)
{
    return path == area || area == QLatin1String("/") || path.startsWith(area + QLatin1Char('/'));
}

// "/home/me/Documents" -> "~/Documents", for messages
QString shownPath(const QString &path)
{
    const QString home = QDir::homePath();
    if (path == home || path.startsWith(home + QLatin1Char('/')))
        return QLatin1Char('~') + path.mid(home.size());
    return path;
}

QStringList cleanList(const QStringList &list)
{
    QStringList out;
    for (const QString &item : list) {
        const QString trimmed = item.trimmed();
        if (!trimmed.isEmpty() && !out.contains(trimmed))
            out.append(trimmed);
    }
    return out;
}

QString findProgram(const QString &name)
{
    QString path = QStandardPaths::findExecutable(name);
    if (path.isEmpty())
        path = QStandardPaths::findExecutable(name, {QStringLiteral("/usr/local/bin"), QStringLiteral("/usr/bin")});
    return path;
}

QNetworkRequest jsonRequest(const QUrl &url, int timeout)
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setTransferTimeout(timeout);
    return request;
}

bool isConnectionError(QNetworkReply::NetworkError error)
{
    switch (error) {
    case QNetworkReply::ConnectionRefusedError:
    case QNetworkReply::RemoteHostClosedError:
    case QNetworkReply::HostNotFoundError:
    case QNetworkReply::TimeoutError:
    case QNetworkReply::OperationCanceledError:
    case QNetworkReply::TemporaryNetworkFailureError:
    case QNetworkReply::NetworkSessionFailedError:
    case QNetworkReply::UnknownNetworkError:
        return true;
    default:
        return false;
    }
}

} // namespace

AIModule::AIModule(QObject *parent)
    : QObject(parent)
    , m_network(new QNetworkAccessManager(this))
    , m_pollTimer(new QTimer(this))
{
    m_pollTimer->setSingleShot(true);
    loadConfig();
    m_assistantBinary = findProgram(AssistantProgram);
    m_llmfitMissing = findProgram(QStringLiteral("llmfit")).isEmpty();
}

// ---------------------------------------------------------------- config

void AIModule::loadConfig()
{
    QSettings settings(ConfigOrganization, ConfigApplication);

    // Older builds wrote the keys inside an [ai] group; keep the values, drop the group
    const QStringList legacyKeys = {QStringLiteral("provider"), QStringLiteral("model")};
    bool hasLegacy = false;
    for (const QString &key : legacyKeys)
        hasLegacy = hasLegacy || settings.contains(LegacyGroup + QLatin1Char('/') + key);
    if (hasLegacy) {
        for (const QString &key : legacyKeys) {
            const QString legacy = settings.value(LegacyGroup + QLatin1Char('/') + key).toString();
            if (settings.value(key).toString().isEmpty() && !legacy.isEmpty())
                settings.setValue(key, legacy);
        }
        settings.remove(LegacyGroup);
        settings.sync();
    }

    m_provider = settings.value(QStringLiteral("provider")).toString();
    if (m_provider.isEmpty())
        m_provider = QStringLiteral("ollama");
    m_model = settings.value(QStringLiteral("model")).toString();
    m_think = settings.value(QStringLiteral("think"), false).toBool();
    loadAssistantConfig(settings);
}

// ---------------------------------------------------------------- assistant

void AIModule::loadAssistantConfig(const QSettings &settings)
{
    m_assistantRead = settings.value(KeyAssistantRead, true).toBool();
    m_assistantWrite = settings.value(KeyAssistantWrite, false).toBool();
    m_assistantTools = settings.contains(KeyAssistantTools)
        ? cleanList(settings.value(KeyAssistantTools).toStringList())
        : DefaultAssistantTools;
    m_assistantFolders = settings.contains(KeyAssistantFolders)
        ? cleanList(settings.value(KeyAssistantFolders).toStringList())
        : defaultAssistantFolders();
}

QStringList AIModule::defaultAssistantFolders()
{
    static const QStringList names = {
        QStringLiteral("Documents"), QStringLiteral("Documentos"), QStringLiteral("Downloads"),
        QStringLiteral("Desktop"), QStringLiteral("Área de Trabalho"), QStringLiteral("Pictures"),
        QStringLiteral("Imagens"),
    };
    const QDir home = QDir::home();
    QStringList folders;
    for (const QString &name : names) {
        const QString path = home.absoluteFilePath(name);
        if (QFileInfo(path).isDir() && !folders.contains(path))
            folders.append(path);
    }
    return folders;
}

// All four keys at once, so the assistant never sees a half-written set
void AIModule::writeAssistantConfig()
{
    QSettings settings(ConfigOrganization, ConfigApplication);
    settings.setValue(KeyAssistantRead, m_assistantRead);
    settings.setValue(KeyAssistantWrite, m_assistantWrite);
    settings.setValue(KeyAssistantTools, m_assistantTools);
    settings.setValue(KeyAssistantFolders, m_assistantFolders);
    settings.sync();
    emit assistantChanged();
}

void AIModule::setAssistantRead(bool on)
{
    if (on == m_assistantRead)
        return;
    m_assistantRead = on;
    writeAssistantConfig();
}

void AIModule::setAssistantWrite(bool on)
{
    if (on == m_assistantWrite)
        return;
    m_assistantWrite = on;
    writeAssistantConfig();
}

void AIModule::setAssistantTool(const QString &id, bool enabled)
{
    if (id.isEmpty() || m_assistantTools.contains(id) == enabled)
        return;
    if (enabled)
        m_assistantTools.append(id);
    else
        m_assistantTools.removeAll(id);
    writeAssistantConfig();
}

QStringList AIModule::assistantBlockedAreas() const
{
    QStringList areas;
    for (const QString &path : BlockedHomePaths)
        areas.append(QStringLiteral("~/") + path);
    return areas + BlockedFilePatterns;
}

QString AIModule::addAssistantFolder(const QUrl &folder)
{
    const QString path = folder.isLocalFile() ? folder.toLocalFile() : folder.toString();
    const QFileInfo info(path);
    if (path.isEmpty() || !info.isAbsolute() || !info.isDir())
        return tr("“%1” is not a folder.").arg(shownPath(path));

    const QString resolved = resolvedPath(path);
    const QString home = resolvedPath(QDir::homePath());
    if (isSameOrInside(home, resolved))
        return tr("The assistant can't have your whole home folder or the whole system. Choose a more specific folder, like Documents.");

    for (const QString &blocked : BlockedHomePaths) {
        const QString area = resolvedPath(home + QLatin1Char('/') + blocked);
        if (isSameOrInside(resolved, area))
            return tr("“%1” holds passwords or keys. It is always blocked for the assistant.").arg(shownPath(path));
    }

    for (const QString &existing : std::as_const(m_assistantFolders)) {
        if (resolved == resolvedPath(existing))
            return tr("“%1” is already in the list.").arg(shownPath(path));
        if (isSameOrInside(resolved, resolvedPath(existing)))
            return tr("“%1” is already allowed through “%2”.").arg(shownPath(path), shownPath(existing));
    }

    m_assistantFolders.append(resolved);
    writeAssistantConfig();
    return {};
}

void AIModule::removeAssistantFolder(const QString &path)
{
    if (m_assistantFolders.removeAll(path) > 0)
        writeAssistantConfig();
}

QString AIModule::displayPath(const QString &path) const
{
    return shownPath(path);
}

void AIModule::openAssistant()
{
    m_assistantBinary = findProgram(AssistantProgram);
    if (m_assistantBinary.isEmpty()) {
        emit assistantChanged();
        return;
    }
    if (!QProcess::startDetached(m_assistantBinary, {}))
        setError(tr("Could not open the assistant."));
}

void AIModule::setThink(bool think)
{
    if (think == m_think)
        return;
    QSettings settings(ConfigOrganization, ConfigApplication);
    settings.setValue(QStringLiteral("think"), think);
    settings.sync();
    m_think = think;
    emit configChanged();
}

bool AIModule::modelCanUseTools() const
{
    const QString current = normalizedName(m_model);
    return std::any_of(m_installed.cbegin(), m_installed.cend(), [&current](const Installed &m) {
        return m.tools && normalizedName(m.name) == current;
    });
}

bool AIModule::modelCanThink() const
{
    const QString current = normalizedName(m_model);
    return std::any_of(m_installed.cbegin(), m_installed.cend(), [&current](const Installed &m) {
        return m.thinking && normalizedName(m.name) == current;
    });
}

void AIModule::writeConfig(const QString &provider, const QString &model)
{
    QSettings settings(ConfigOrganization, ConfigApplication);
    settings.setValue(QStringLiteral("provider"), provider);
    settings.setValue(QStringLiteral("model"), model);
    settings.sync();
    m_provider = provider;
    m_model = model;
    emit configChanged();
    emit installedModelsChanged();
    emit recommendationsChanged();
}

void AIModule::setDefaultModel(const QString &name)
{
    if (name.isEmpty() || (name == m_model && m_provider == QLatin1String("ollama")))
        return;
    writeConfig(QStringLiteral("ollama"), name);
}

bool AIModule::modelInstalled() const
{
    const QString wanted = normalizedName(m_model);
    return std::any_of(m_installed.cbegin(), m_installed.cend(),
                       [&wanted](const Installed &m) { return normalizedName(m.name) == wanted; });
}

// ---------------------------------------------------------------- Ollama server

QUrl AIModule::apiUrl(const QString &path) const
{
    // Same variable the ollama CLI honours. "0.0.0.0" is a bind address: talk to localhost.
    QString host = qEnvironmentVariable("OLLAMA_HOST").trimmed();
    if (host.isEmpty())
        host = QStringLiteral("127.0.0.1:11434");
    if (!host.contains(QLatin1String("://")))
        host.prepend(QLatin1String("http://"));
    QUrl url(host);
    if (url.host().isEmpty() || url.host() == QLatin1String("0.0.0.0"))
        url.setHost(QStringLiteral("127.0.0.1"));
    if (url.port() < 0)
        url.setPort(11434);
    url.setPath(path);
    return url;
}

bool AIModule::remoteServer() const
{
    static const QStringList local = {QStringLiteral("127.0.0.1"), QStringLiteral("localhost"), QStringLiteral("::1")};
    return !local.contains(apiUrl({}).host());
}

QString AIModule::serverAddress() const
{
    const QUrl url = apiUrl({});
    return url.host() + QLatin1Char(':') + QString::number(url.port());
}

bool AIModule::canStartOllama() const
{
    return !remoteServer() && m_ollamaState == Stopped && !m_serviceActive
        && (m_hasService || !m_ollamaBinary.isEmpty());
}

void AIModule::setOllamaState(int state)
{
    if (m_ollamaState == state)
        return;
    m_ollamaState = state;
    if (state != Running) {
        m_ollamaVersion.clear();
        if (!m_installed.isEmpty()) {
            m_installed.clear();
            emit installedModelsChanged();
        }
    }
    emit ollamaChanged();
}

void AIModule::refresh()
{
    if (m_pollTimer->isActive())
        return; // a check is already in flight
    m_pollTimer->start(ApiTimeoutMs + 2000); // guard against overlapping checks
    const QString assistant = findProgram(AssistantProgram);
    if (assistant != m_assistantBinary) {
        m_assistantBinary = assistant;
        emit assistantChanged();
    }
    checkVersion();
}

void AIModule::checkVersion()
{
    QNetworkReply *reply = m_network->get(jsonRequest(apiUrl(QStringLiteral("/api/version")), ApiTimeoutMs));
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();
        const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
        if (reply->error() == QNetworkReply::NoError && obj.contains(QStringLiteral("version"))) {
            m_pollTimer->stop();
            const bool wasStarting = m_startAttempts > 0;
            m_startAttempts = 0;
            m_ollamaVersion = obj.value(QStringLiteral("version")).toString();
            setOllamaState(Running);
            emit ollamaChanged();
            if (wasStarting)
                setInfo(tr("Ollama is running."));
            fetchTags();
            return;
        }

        if (m_startAttempts > 0) {
            if (--m_startAttempts > 0) {
                m_pollTimer->stop();
                setOllamaState(Starting);
                return;
            }
            setError(tr("Ollama did not start. Check the service with: systemctl status ollama"));
        }
        checkInstallation();
    });
}

void AIModule::checkInstallation()
{
    m_ollamaBinary = findProgram(QStringLiteral("ollama"));

    m_serviceActive = false;
    if (remoteServer()) {
        m_pollTimer->stop();
        m_hasService = false;
        setOllamaState(Stopped);
        emit ollamaChanged();
        return;
    }

    const QString systemctl = findProgram(QStringLiteral("systemctl"));
    if (systemctl.isEmpty()) {
        m_pollTimer->stop();
        m_hasService = false;
        setOllamaState(m_ollamaBinary.isEmpty() ? NotInstalled : Stopped);
        emit ollamaChanged();
        return;
    }

    auto *process = new QProcess(this);
    connect(process, &QProcess::finished, this, [this, process] {
        process->deleteLater();
        m_pollTimer->stop();
        QString loadState, activeState;
        const QStringList lines = QString::fromUtf8(process->readAllStandardOutput()).split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            if (line.startsWith(QLatin1String("LoadState=")))
                loadState = line.mid(10).trimmed();
            else if (line.startsWith(QLatin1String("ActiveState=")))
                activeState = line.mid(12).trimmed();
        }
        m_hasService = loadState == QLatin1String("loaded");
        m_serviceActive = m_hasService && activeState == QLatin1String("active");
        if (m_hasService && (activeState == QLatin1String("activating") || activeState == QLatin1String("reloading")))
            setOllamaState(Starting);
        else if (m_hasService || !m_ollamaBinary.isEmpty())
            setOllamaState(Stopped);
        else
            setOllamaState(NotInstalled);
        emit ollamaChanged();
    });
    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        process->deleteLater();
        m_pollTimer->stop();
        m_hasService = false;
        setOllamaState(m_ollamaBinary.isEmpty() ? NotInstalled : Stopped);
        emit ollamaChanged();
    });
    process->start(systemctl, {QStringLiteral("show"), QStringLiteral("ollama.service"),
                               QStringLiteral("--property=LoadState,ActiveState")});
}

void AIModule::startOllama()
{
    if (!canStartOllama())
        return;
    clearMessages();

    if (!m_hasService) {
        // Installed by hand, without the systemd unit: run it as this user
        if (!QProcess::startDetached(m_ollamaBinary, {QStringLiteral("serve")})) {
            setError(tr("Could not start Ollama."));
            return;
        }
        m_startAttempts = StartPolls;
        setOllamaState(Starting);
        return;
    }

    const QString pkexec = findProgram(QStringLiteral("pkexec"));
    const QString systemctl = findProgram(QStringLiteral("systemctl"));
    if (pkexec.isEmpty() || systemctl.isEmpty()) {
        setError(tr("Start it in a terminal with: sudo systemctl enable --now ollama"));
        return;
    }

    auto *process = new QProcess(this);
    changeBusy(1);
    connect(process, &QProcess::finished, this, [this, process](int exitCode, QProcess::ExitStatus status) {
        process->deleteLater();
        changeBusy(-1);
        if (status == QProcess::NormalExit && exitCode == 0) {
            m_startAttempts = StartPolls;
            setOllamaState(Starting);
            refresh();
        } else if (exitCode == 126 || exitCode == 127) {
            setError(tr("Authorization was cancelled."));
        } else {
            setError(tr("Could not start the Ollama service: %1")
                         .arg(QString::fromUtf8(process->readAllStandardError()).trimmed()));
        }
    });
    process->start(pkexec, {systemctl, QStringLiteral("start"), QStringLiteral("ollama.service")});
}

void AIModule::fetchTags()
{
    QNetworkReply *reply = m_network->get(jsonRequest(apiUrl(QStringLiteral("/api/tags")), ApiTimeoutMs));
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError)
            return;
        QList<Installed> models;
        const QJsonArray array = QJsonDocument::fromJson(reply->readAll()).object().value(QStringLiteral("models")).toArray();
        for (const QJsonValue &value : array) {
            const QJsonObject obj = value.toObject();
            const QJsonObject details = obj.value(QStringLiteral("details")).toObject();
            Installed m;
            m.name = obj.value(QStringLiteral("name")).toString();
            if (m.name.isEmpty())
                m.name = obj.value(QStringLiteral("model")).toString();
            m.parameterSize = details.value(QStringLiteral("parameter_size")).toString();
            m.quantization = details.value(QStringLiteral("quantization_level")).toString();
            m.size = obj.value(QStringLiteral("size")).toVariant().toLongLong();

            const QVariantList caps = obj.value(QStringLiteral("capabilities")).toArray().toVariantList();
            if (!caps.isEmpty()) {
                m.embedding = caps.contains(QStringLiteral("embedding")) && !caps.contains(QStringLiteral("completion"));
                m.thinking = caps.contains(QStringLiteral("thinking"));
                m.tools = caps.contains(QStringLiteral("tools"));
            } else {
                const QString family = details.value(QStringLiteral("family")).toString();
                m.embedding = family.contains(QLatin1String("bert")) || m.name.contains(QLatin1String("embed"));
            }
            if (!m.name.isEmpty())
                models.append(m);
        }
        std::sort(models.begin(), models.end(), [](const Installed &a, const Installed &b) {
            return a.name < b.name;
        });
        m_installed = models;
        emit installedModelsChanged();
        emit recommendationsChanged();
    });
}

QVariantList AIModule::installedModels() const
{
    const QLocale locale;
    const QString current = normalizedName(m_model);
    QVariantList list;
    for (const Installed &m : m_installed) {
        QStringList details;
        if (!m.parameterSize.isEmpty())
            details << m.parameterSize;
        if (!m.quantization.isEmpty())
            details << m.quantization;
        if (m.size > 0)
            details << locale.formattedDataSize(m.size, 1, QLocale::DataSizeSIFormat);

        QVariantMap map{
            {QStringLiteral("name"), m.name},
            {QStringLiteral("details"), details.join(QStringLiteral(" · "))},
            {QStringLiteral("embedding"), m.embedding},
            {QStringLiteral("thinking"), m.thinking},
            {QStringLiteral("tools"), m.tools},
            {QStringLiteral("inUse"), normalizedName(m.name) == current},
            {QStringLiteral("fitLevel"), QString()},
            {QStringLiteral("fitText"), QString()},
        };
        const auto fit = m_fitByName.constFind(normalizedName(m.name));
        if (!m.embedding && fit != m_fitByName.cend()) {
            const QVariantMap f = fitToMap(*fit);
            map.insert(QStringLiteral("fitLevel"), f.value(QStringLiteral("fitLevel")));
            map.insert(QStringLiteral("fitText"), f.value(QStringLiteral("fitText")));
            map.insert(QStringLiteral("runMode"), f.value(QStringLiteral("runMode")));
            map.insert(QStringLiteral("speed"), f.value(QStringLiteral("speed")));
        }
        list.append(map);
    }
    return list;
}

// ---------------------------------------------------------------- pull / delete

bool AIModule::isValidModelName(const QString &name) const
{
    static const QRegularExpression re(
        QStringLiteral("^([a-z0-9][a-z0-9._-]*/)?[a-z0-9][a-z0-9._-]*(:[a-z0-9._-]+)?$"));
    return name.size() <= 200 && re.match(name).hasMatch();
}

void AIModule::pull(const QString &name)
{
    const QString model = name.trimmed();
    if (pulling())
        return;
    clearMessages();
    if (!isValidModelName(model)) {
        setError(tr("“%1” is not a valid model name. Use names like llama3.2:3b or user/model:tag.").arg(model));
        return;
    }
    if (m_ollamaState != Running) {
        setError(tr("Start Ollama before downloading models."));
        return;
    }

    m_pullModel = model;
    m_pullBuffer.clear();
    m_pullLayers.clear();
    m_pullStatus.clear();
    m_pullProgress = -1;
    m_pullFailure.clear();
    m_pullSucceeded = false;
    m_pullCancelled = false;
    m_speedBytes = 0;
    m_speed = 0;
    m_speedTimer.start();

    const QJsonObject body{{QStringLiteral("model"), model}, {QStringLiteral("stream"), true}};
    // No overall timeout; only give up when the server goes silent
    m_pullReply = m_network->post(jsonRequest(apiUrl(QStringLiteral("/api/pull")), 120000),
                                  QJsonDocument(body).toJson(QJsonDocument::Compact));
    connect(m_pullReply, &QNetworkReply::readyRead, this, &AIModule::readPullData);
    connect(m_pullReply, &QNetworkReply::finished, this, &AIModule::finishPull);
    updatePullDetail();
    emit pullChanged();
}

void AIModule::cancelPull()
{
    if (!m_pullReply)
        return;
    m_pullCancelled = true;
    m_pullReply->abort(); // emits finished
}

void AIModule::readPullData()
{
    if (!m_pullReply)
        return;
    m_pullBuffer += m_pullReply->readAll();

    int newline;
    while ((newline = m_pullBuffer.indexOf('\n')) >= 0) {
        const QByteArray line = m_pullBuffer.left(newline).trimmed();
        m_pullBuffer.remove(0, newline + 1);
        if (line.isEmpty())
            continue;
        const QJsonObject obj = QJsonDocument::fromJson(line).object();
        if (obj.contains(QStringLiteral("error"))) {
            m_pullFailure = obj.value(QStringLiteral("error")).toString();
            continue;
        }
        const QString status = obj.value(QStringLiteral("status")).toString();
        if (status == QLatin1String("success"))
            m_pullSucceeded = true;
        if (!status.isEmpty())
            m_pullStatus = status;
        const QString digest = obj.value(QStringLiteral("digest")).toString();
        const qint64 total = obj.value(QStringLiteral("total")).toVariant().toLongLong();
        if (!digest.isEmpty() && total > 0)
            m_pullLayers.insert(digest, {obj.value(QStringLiteral("completed")).toVariant().toLongLong(), total});
    }
    updatePullDetail();
    emit pullChanged();
}

void AIModule::updatePullDetail()
{
    const QLocale locale;
    qint64 completed = 0, total = 0;
    for (const auto &layer : std::as_const(m_pullLayers)) {
        completed += layer.first;
        total += layer.second;
    }

    const qint64 elapsed = m_speedTimer.elapsed();
    if (elapsed >= 1000) {
        const double current = std::max<qint64>(0, completed - m_speedBytes) * 1000.0 / elapsed;
        m_speed = m_speed > 0 ? m_speed * 0.6 + current * 0.4 : current;
        m_speedBytes = completed;
        m_speedTimer.restart();
    }

    if (m_pullStatus.startsWith(QLatin1String("pulling")) && m_pullStatus != QLatin1String("pulling manifest") && total > 0) {
        m_pullProgress = std::clamp(double(completed) / double(total), 0.0, 1.0);
        QString detail = tr("%1% · %2 of %3")
                             .arg(int(m_pullProgress * 100))
                             .arg(locale.formattedDataSize(completed, 1, QLocale::DataSizeSIFormat),
                                  locale.formattedDataSize(total, 1, QLocale::DataSizeSIFormat));
        if (m_speed > 1)
            detail += QStringLiteral(" · ") + tr("%1/s").arg(locale.formattedDataSize(qint64(m_speed), 1, QLocale::DataSizeSIFormat));
        m_pullDetail = detail;
    } else if (m_pullStatus.startsWith(QLatin1String("verifying"))) {
        m_pullProgress = -1;
        m_pullDetail = tr("Verifying the download…");
    } else if (m_pullStatus.startsWith(QLatin1String("writing")) || m_pullStatus == QLatin1String("success")) {
        m_pullProgress = -1;
        m_pullDetail = tr("Finishing…");
    } else {
        m_pullProgress = -1;
        m_pullDetail = tr("Contacting the Ollama library…");
    }
}

void AIModule::finishPull()
{
    QNetworkReply *reply = m_pullReply;
    if (!reply)
        return;
    readPullData();
    reply->deleteLater();
    m_pullReply = nullptr;

    const QString model = m_pullModel;
    if (m_pullCancelled) {
        setInfo(tr("Download of %1 cancelled.").arg(model));
    } else if (m_pullSucceeded && m_pullFailure.isEmpty()) {
        setInfo(tr("%1 is ready to use.").arg(model));
        if (m_model.isEmpty())
            writeConfig(QStringLiteral("ollama"), model);
    } else {
        QString raw = m_pullFailure;
        if (raw.isEmpty()) {
            const QByteArray rest = m_pullBuffer.trimmed();
            raw = QJsonDocument::fromJson(rest).object().value(QStringLiteral("error")).toString();
        }
        if (raw.isEmpty() && isConnectionError(reply->error()))
            setError(tr("Lost the connection to Ollama at %1.").arg(serverAddress()));
        else if (raw.contains(QLatin1String("file does not exist")) || raw.contains(QLatin1String("not found"))
                 || raw.contains(QLatin1String("manifest unknown")))
            setError(tr("Ollama doesn't know a model called “%1”. Check the name at ollama.com/library.").arg(model));
        else if (raw.contains(QLatin1String("no space left")))
            setError(tr("There is not enough free disk space for %1.").arg(model));
        else if (!raw.isEmpty())
            setError(tr("Ollama could not download %1: %2").arg(model, raw));
        else
            setError(tr("The download of %1 failed.").arg(model));
    }

    m_pullModel.clear();
    m_pullLayers.clear();
    m_pullProgress = -1;
    m_pullDetail.clear();
    emit pullChanged();
    fetchTags();
}

void AIModule::removeModel(const QString &name)
{
    if (name.isEmpty() || m_ollamaState != Running)
        return;
    clearMessages();
    const QJsonObject body{{QStringLiteral("model"), name}};
    QNetworkReply *reply = m_network->sendCustomRequest(jsonRequest(apiUrl(QStringLiteral("/api/delete")), 30000),
                                                        QByteArrayLiteral("DELETE"),
                                                        QJsonDocument(body).toJson(QJsonDocument::Compact));
    changeBusy(1);
    connect(reply, &QNetworkReply::finished, this, [this, reply, name] {
        reply->deleteLater();
        changeBusy(-1);
        const QByteArray data = reply->readAll();
        if (reply->error() == QNetworkReply::NoError) {
            setInfo(tr("%1 was removed.").arg(name));
        } else if (isConnectionError(reply->error())) {
            setError(tr("Could not reach Ollama at %1.").arg(serverAddress()));
        } else {
            const QString raw = QJsonDocument::fromJson(data).object().value(QStringLiteral("error")).toString();
            setError(raw.isEmpty() ? tr("Could not remove %1.").arg(name)
                                   : tr("Could not remove %1: %2").arg(name, raw));
        }
        fetchTags();
    });
}

// ---------------------------------------------------------------- llmfit

bool AIModule::llmfitAvailable() const
{
    return !m_llmfitMissing;
}

void AIModule::setUseCase(const QString &useCase)
{
    static const QStringList known = {QStringLiteral("chat"), QStringLiteral("general"),
                                      QStringLiteral("coding"), QStringLiteral("reasoning")};
    if (!known.contains(useCase) || useCase == m_useCase)
        return;
    m_useCase = useCase;
    emit useCaseChanged();
    emit recommendationsChanged();
    if (!m_recommendations.contains(useCase)) {
        m_llmfitError.clear();
        queueLlmfit(useCase);
    }
}

void AIModule::loadRecommendations()
{
    // Hardware doesn't change: reuse what this session already found
    if (!m_llmfitError.isEmpty())
        return;
    if (!m_recommendations.contains(m_useCase))
        queueLlmfit(m_useCase);
    if (!m_fitLoaded)
        queueLlmfit(QStringLiteral("fit"));
}

void AIModule::refreshRecommendations()
{
    m_llmfitMissing = findProgram(QStringLiteral("llmfit")).isEmpty();
    if (llmfitBusy())
        return;
    m_recommendations.clear();
    m_fitByName.clear();
    m_fitLoaded = false;
    m_llmfitError.clear();
    emit recommendationsChanged();
    emit installedModelsChanged();
    queueLlmfit(m_useCase);
    queueLlmfit(QStringLiteral("fit"));
}

void AIModule::queueLlmfit(const QString &kind)
{
    if (m_llmfitMissing) {
        emit llmfitChanged();
        return;
    }
    for (const LlmfitJob &job : std::as_const(m_llmfitQueue)) {
        if (job.kind == kind)
            return;
    }
    LlmfitJob job;
    job.kind = kind;
    if (kind == QLatin1String("fit"))
        job.arguments = {QStringLiteral("fit"), QStringLiteral("--json"), QStringLiteral("--no-dashboard")};
    else
        job.arguments = {QStringLiteral("recommend"), QStringLiteral("--json"), QStringLiteral("--no-dashboard"),
                         QStringLiteral("-n"), QStringLiteral("10000"), QStringLiteral("--use-case"), kind};
    m_llmfitQueue.append(job);
    runNextLlmfit();
    emit llmfitChanged();
}

void AIModule::runNextLlmfit()
{
    if (m_llmfitProcess || m_llmfitParsing || m_llmfitQueue.isEmpty())
        return;
    const QString program = findProgram(QStringLiteral("llmfit"));
    if (program.isEmpty()) {
        m_llmfitMissing = true;
        m_llmfitQueue.clear();
        emit llmfitChanged();
        return;
    }

    const LlmfitJob job = m_llmfitQueue.takeFirst();
    auto *process = new QProcess(this);
    m_llmfitProcess = process;
    process->setProcessChannelMode(QProcess::SeparateChannels);

    auto *timeout = new QTimer(process);
    timeout->setSingleShot(true);
    connect(timeout, &QTimer::timeout, process, [process] { process->kill(); });

    connect(process, &QProcess::finished, this, [this, process, job](int exitCode, QProcess::ExitStatus status) {
        process->deleteLater();
        m_llmfitProcess = nullptr;
        const QByteArray out = process->readAllStandardOutput();
        if (status != QProcess::NormalExit || (exitCode != 0 && out.isEmpty())) {
            LlmfitResult failed;
            failed.error = status != QProcess::NormalExit
                ? tr("llmfit took too long to answer.")
                : tr("llmfit failed: %1").arg(QString::fromUtf8(process->readAllStandardError()).trimmed().left(300));
            llmfitFinished(job.kind, failed);
            return;
        }
        // Up to ~20 MB of JSON: parse it off the UI thread
        m_llmfitParsing = true;
        auto *watcher = new QFutureWatcher<LlmfitResult>(this);
        connect(watcher, &QFutureWatcher<LlmfitResult>::finished, this, [this, watcher, job] {
            watcher->deleteLater();
            m_llmfitParsing = false;
            llmfitFinished(job.kind, watcher->result());
        });
        watcher->setFuture(QtConcurrent::run(&AIModule::parseLlmfit, out));
    });
    connect(process, &QProcess::errorOccurred, this, [this, process, job](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        process->deleteLater();
        m_llmfitProcess = nullptr;
        LlmfitResult failed;
        failed.error = tr("Could not run llmfit.");
        llmfitFinished(job.kind, failed);
    });

    process->start(program, job.arguments);
    timeout->start(LlmfitTimeoutMs);
}

AIModule::LlmfitResult AIModule::parseLlmfit(const QByteArray &json)
{
    LlmfitResult result;
    QJsonParseError parseError;
    const QJsonObject root = QJsonDocument::fromJson(json, &parseError).object();
    if (parseError.error != QJsonParseError::NoError) {
        result.error = tr("llmfit gave an answer this page can't read.");
        return result;
    }
    if (root.contains(QStringLiteral("error"))) {
        const QJsonValue err = root.value(QStringLiteral("error"));
        result.error = tr("llmfit failed: %1")
                           .arg(err.isObject() ? err.toObject().value(QStringLiteral("message")).toString() : err.toString());
        return result;
    }

    const QLocale locale;
    const QJsonObject system = root.value(QStringLiteral("system")).toObject();
    QStringList summary;
    const QString cpu = system.value(QStringLiteral("cpu_name")).toString().simplified();
    if (!cpu.isEmpty())
        summary << cpu;
    const double ram = system.value(QStringLiteral("total_ram_gb")).toDouble();
    if (ram > 0)
        summary << tr("%1 GB RAM").arg(locale.toString(qRound(ram)));
    const QString gpu = system.value(QStringLiteral("gpu_name")).toString().simplified();
    const double vram = system.value(QStringLiteral("gpu_vram_gb")).toDouble();
    if (system.value(QStringLiteral("has_gpu")).toBool() && !gpu.isEmpty())
        summary << (vram > 0 ? tr("%1 with %2 GB").arg(gpu, locale.toString(vram, 'g', 3)) : gpu);
    else
        summary << tr("no dedicated GPU");
    result.systemSummary = summary.join(QStringLiteral(" · "));

    QSet<QString> seen;
    const QJsonArray models = root.value(QStringLiteral("models")).toArray();
    for (const QJsonValue &value : models) {
        const QJsonObject obj = value.toObject();
        const QString ollamaName = obj.value(QStringLiteral("ollama_name")).toString();
        if (ollamaName.isEmpty())
            continue;
        FitInfo fit;
        fit.ollamaName = ollamaName;
        fit.fitLevel = obj.value(QStringLiteral("fit_level")).toString();
        fit.runMode = obj.value(QStringLiteral("run_mode")).toString();
        fit.score = obj.value(QStringLiteral("score")).toDouble();
        fit.tps = obj.value(QStringLiteral("estimated_tps")).toDouble();
        fit.diskGb = obj.value(QStringLiteral("disk_size_gb")).toDouble();
        fit.memoryGb = obj.value(QStringLiteral("memory_required_gb")).toDouble();
        fit.parameters = obj.value(QStringLiteral("parameter_count")).toString();
        result.models.append(fit);
    }
    std::stable_sort(result.models.begin(), result.models.end(), [](const FitInfo &a, const FitInfo &b) {
        return a.score > b.score;
    });
    // Several Hugging Face entries can map to one Ollama name: keep the best
    QList<FitInfo> unique;
    for (const FitInfo &fit : std::as_const(result.models)) {
        const QString key = normalizedName(fit.ollamaName);
        if (seen.contains(key))
            continue;
        seen.insert(key);
        unique.append(fit);
    }
    result.models = unique;
    result.ok = true;
    return result;
}

void AIModule::llmfitFinished(const QString &kind, const LlmfitResult &result)
{
    if (!result.ok) {
        m_llmfitError = result.error;
    } else {
        if (!result.systemSummary.isEmpty())
            m_systemSummary = result.systemSummary;
        if (kind == QLatin1String("fit")) {
            m_fitByName.clear();
            for (const FitInfo &fit : result.models)
                m_fitByName.insert(normalizedName(fit.ollamaName), fit);
            m_fitLoaded = true;
            emit installedModelsChanged();
        } else {
            QList<FitInfo> usable;
            for (const FitInfo &fit : result.models) {
                if (fit.fitLevel != QLatin1String("Too Tight"))
                    usable.append(fit);
            }
            m_recommendations.insert(kind, usable);
            emit recommendationsChanged();
        }
    }
    emit llmfitChanged();
    runNextLlmfit();
}

QVariantList AIModule::recommendations() const
{
    QVariantList list;
    const auto it = m_recommendations.constFind(m_useCase);
    if (it == m_recommendations.cend())
        return list;
    for (const FitInfo &fit : *it)
        list.append(fitToMap(fit));
    return list;
}

QVariantMap AIModule::fitToMap(const FitInfo &fit) const
{
    const QLocale locale;
    const QString key = normalizedName(fit.ollamaName);
    const bool installed = std::any_of(m_installed.cbegin(), m_installed.cend(),
                                       [&key](const Installed &m) { return normalizedName(m.name) == key; });
    QString speed;
    if (fit.tps > 0)
        speed = tr("≈ %1 tokens/s").arg(locale.toString(qRound(fit.tps)));
    return {
        {QStringLiteral("name"), fit.ollamaName},
        {QStringLiteral("fitLevel"), fit.fitLevel},
        {QStringLiteral("fitText"), fitText(fit.fitLevel)},
        {QStringLiteral("runMode"), runModeText(fit.runMode)},
        {QStringLiteral("speed"), speed},
        {QStringLiteral("download"), fit.diskGb > 0 ? formatGb(fit.diskGb) : QString()},
        {QStringLiteral("memory"), fit.memoryGb > 0 ? formatGb(fit.memoryGb) : QString()},
        {QStringLiteral("parameters"), fit.parameters},
        {QStringLiteral("installed"), installed},
        {QStringLiteral("inUse"), key == normalizedName(m_model)},
    };
}

QString AIModule::fitText(const QString &level) const
{
    if (level == QLatin1String("Perfect"))
        return tr("Perfect fit");
    if (level == QLatin1String("Good"))
        return tr("Good fit");
    if (level == QLatin1String("Marginal"))
        return tr("At the limit");
    if (level == QLatin1String("Too Tight"))
        return tr("Too heavy for this computer");
    return level;
}

QString AIModule::runModeText(const QString &mode) const
{
    if (mode == QLatin1String("GPU"))
        return tr("Runs on the GPU");
    if (mode == QLatin1String("CPU+GPU"))
        return tr("Runs on the CPU and GPU");
    if (mode == QLatin1String("CPU"))
        return tr("Runs on the CPU");
    if (mode == QLatin1String("MoE"))
        return tr("Runs on the GPU (MoE)");
    return mode;
}

// ---------------------------------------------------------------- helpers

QString AIModule::normalizedName(const QString &name)
{
    QString n = name.trimmed().toLower();
    if (n.isEmpty())
        return n;
    const int slash = n.lastIndexOf(QLatin1Char('/'));
    if (n.indexOf(QLatin1Char(':'), slash + 1) < 0)
        n += QLatin1String(":latest");
    return n;
}

QString AIModule::formatGb(double gb) const
{
    return tr("%1 GB").arg(QLocale().toString(gb, 'f', 1));
}

void AIModule::setError(const QString &text)
{
    m_errorText = text;
    if (!text.isEmpty())
        m_infoText.clear();
    emit messageChanged();
}

void AIModule::setInfo(const QString &text)
{
    m_infoText = text;
    if (!text.isEmpty())
        m_errorText.clear();
    emit messageChanged();
}

void AIModule::clearMessages()
{
    if (m_errorText.isEmpty() && m_infoText.isEmpty())
        return;
    m_errorText.clear();
    m_infoText.clear();
    emit messageChanged();
}

void AIModule::changeBusy(int delta)
{
    const bool was = busy();
    m_busy = std::max(0, m_busy + delta);
    if (was != busy())
        emit busyChanged();
}
