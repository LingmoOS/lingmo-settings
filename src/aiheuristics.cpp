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

#include "aiheuristics.h"

#include <QRegularExpression>

namespace AIHeuristics {

namespace {

// Name without registry/user prefix, lowercase: "hf.co/bartowski/Qwen2.5-7B-GGUF:Q4" -> "qwen2.5-7b-gguf:q4"
QString baseName(const QString &name)
{
    QString n = name.trimmed().toLower();
    const int slash = n.lastIndexOf(QLatin1Char('/'));
    return slash >= 0 ? n.mid(slash + 1) : n;
}

bool isMultilingualFamily(const QString &n)
{
    // Families trained on many languages, Portuguese included (model cards on ollama.com).
    // llama3 (3.0) itself was English-first; 3.1+ lists Portuguese.
    static const QRegularExpression re(QStringLiteral(
        "^(qwen|gemma|mistral|mixtral|ministral|magistral|aya|command-?r|command-?a|gpt-oss|glm-?4|deepseek-v3)"
        "|^llama-?3[._-]?[1-9]|^llama-?4|^granite-?[3-9]"));
    return re.match(n).hasMatch();
}

// Models made for one narrow job: not for summarising a transcript
bool isSpecialist(const QString &n)
{
    static const QRegularExpression re(QStringLiteral(
        "code|coder|starcoder|embed|guard|shield|ocr|math|sqlcoder|bge|minilm|moondream|llava|-base\\b|:text"));
    return re.match(n).hasMatch();
}

} // namespace

double parameterBillions(const QString &name, const QString &parameterSize)
{
    static const QRegularExpression sizeRe(QStringLiteral("^\\s*([0-9]+(?:\\.[0-9]+)?)\\s*([KMBT])"),
                                           QRegularExpression::CaseInsensitiveOption);
    const QRegularExpressionMatch size = sizeRe.match(parameterSize);
    if (size.hasMatch()) {
        const double value = size.captured(1).toDouble();
        switch (size.captured(2).toUpper().at(0).unicode()) {
        case 'K': return value / 1e6;
        case 'M': return value / 1e3;
        case 'B': return value;
        case 'T': return value * 1e3;
        }
    }

    const QString n = baseName(name);
    // "8x7b": mixture of experts, total size
    static const QRegularExpression moeRe(QStringLiteral("(?<![0-9.])([0-9]+)x([0-9]+(?:\\.[0-9]+)?)b(?![a-z])"));
    const QRegularExpressionMatch moe = moeRe.match(n);
    if (moe.hasMatch())
        return moe.captured(1).toDouble() * moe.captured(2).toDouble();
    // The first "<n>b" / "<n>m" that isn't part of a version ("qwen2.5:3b" -> 3)
    static const QRegularExpression nameRe(QStringLiteral("(?<![0-9.])([0-9]+(?:\\.[0-9]+)?)([bm])(?![a-z])"));
    const QRegularExpressionMatch m = nameRe.match(n);
    if (m.hasMatch())
        return m.captured(2) == QLatin1String("m") ? m.captured(1).toDouble() / 1e3 : m.captured(1).toDouble();
    return -1;
}

QStringList modelTags(const QString &name, const QString &parameterSize, bool embedding, bool tools, bool thinking)
{
    QStringList tags;
    const QString n = baseName(name);
    if (n.startsWith(QLatin1String("whisper")))
        return {TagSubtitles};
    if (embedding)
        return tags;

    const double billions = parameterBillions(name, parameterSize);
    if (tools)
        tags << TagTools;
    if (thinking)
        tags << TagThinking;
    // Picking the best moments of a long transcript needs a capable instruct
    // model: ~3B and up, general purpose
    if (billions >= 2.9 && !isSpecialist(n))
        tags << TagHighlights;
    if (billions > 0 && billions <= 4.5)
        tags << TagFast;
    if (billions >= 12)
        tags << TagAccurate;
    if (isMultilingualFamily(n))
        tags << TagMultilingual;
    return tags;
}

// Sizes and sha256 values: the Hugging Face file listing of ggerganov/whisper.cpp
// (https://huggingface.co/api/models/ggerganov/whisper.cpp/tree/main, "size" and
// "lfs.oid", which is the sha256 of the file), checked 2026-10-17.
// Memory: whisper.cpp README "Memory usage" table (tiny 273 MB, base 388 MB,
// small 852 MB, medium 2.1 GB, large 3.9 GB); turbo and quantised models are
// estimated as their file size plus the overhead of the full model of the same
// encoder size. Speed and Portuguese quality are relative judgements from the
// OpenAI Whisper paper / model card (Portuguese is one of its best languages;
// turbo is large-v3 with 4 decoder layers, close in accuracy and much faster).
const QList<WhisperModel> &whisperCatalogue()
{
    static const QList<WhisperModel> catalogue = {
        {QStringLiteral("tiny"), 77691713, QStringLiteral("be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21"), 273, 5, 1, false},
        {QStringLiteral("base-q5_1"), 59707625, QStringLiteral("422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898"), 300, 5, 1, true},
        {QStringLiteral("base"), 147951465, QStringLiteral("60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe"), 388, 5, 1, false},
        {QStringLiteral("small-q5_1"), 190085487, QStringLiteral("ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb"), 570, 4, 2, true},
        {QStringLiteral("small"), 487601967, QStringLiteral("1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b"), 852, 4, 2, false},
        {QStringLiteral("medium-q5_0"), 539212467, QStringLiteral("19fea4b380c3a618ec4723c3eef2eb785ffba0d0538cf43f8f235e7b3b34220f"), 1100, 2, 3, true},
        {QStringLiteral("medium"), 1533763059, QStringLiteral("6c14d5adee5f86394037b4e4e8b59f1673b6cee10e3cf0b11bbdbee79c156208"), 2100, 2, 3, false},
        {QStringLiteral("large-v3-turbo-q5_0"), 574041195, QStringLiteral("394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2"), 1200, 3, 3, true},
        {QStringLiteral("large-v3-turbo-q8_0"), 874188075, QStringLiteral("317eb69c11673c9de1e1f0d459b253999804ec71ac4c23c17ecf5fbe24e259a1"), 1500, 3, 4, true},
        {QStringLiteral("large-v3-turbo"), 1624555275, QStringLiteral("1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69"), 2200, 3, 4, false},
        {QStringLiteral("large-v3-q5_0"), 1081140203, QStringLiteral("d75795ecff3f83b5faa89d1900604ad8c780abd5739fae406de19f23ecd98ad1"), 2100, 1, 4, true},
        {QStringLiteral("large-v3"), 3095033483, QStringLiteral("64d182b440b98d5203c4f9bd541544d84c605196c4f7b845dfa11fb23594d1e2"), 3900, 1, 4, false},
    };
    return catalogue;
}

const WhisperModel *findWhisperModel(const QString &name)
{
    for (const WhisperModel &model : whisperCatalogue()) {
        if (model.name == name)
            return &model;
    }
    return nullptr;
}

QString recommendWhisperModel(double ramGb, int cores, double vramGb, const QString &gpuVendor)
{
    // whisper.cpp runs on NVIDIA (CUDA) and AMD (ROCm/Vulkan) graphics; Intel iGPUs
    // share system memory and gain little, so they count as CPU only
    const QString vendor = gpuVendor.toLower();
    const bool gpu = (vendor == QLatin1String("nvidia") || vendor == QLatin1String("amd")) && vramGb > 0;

    if (gpu && vramGb >= 4 && ramGb >= 8)
        return QStringLiteral("large-v3-turbo");
    if (gpu && vramGb >= 2 && ramGb >= 4)
        return QStringLiteral("large-v3-turbo-q5_0");
    // CPU only: turbo-q5 is still a few times faster than real time on 8+ cores
    if (ramGb >= 16 && cores >= 8)
        return QStringLiteral("large-v3-turbo-q5_0");
    if (ramGb >= 8 && cores >= 4)
        return QStringLiteral("small");
    if (ramGb >= 4 && cores >= 2)
        return QStringLiteral("base");
    return QStringLiteral("tiny");
}

} // namespace AIHeuristics
