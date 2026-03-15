// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation

public struct ModelInfo: Decodable {
    enum CodingKeys: String, CodingKey {
        case dataset
        case piperVersion = "piper_version"
        case language
        case audio
        case speakersInternal = "speaker_id_map"
        case numberOfSpeakersInternal = "num_speakers"
    }
    
    public let dataset: String?
    public let piperVersion: String
    public let language: Language
    public let audio: Audio
    private let speakersInternal: [String: Int]?
    public var speakers: [String: Int] {
        speakersInternal ?? [:]
    }
    private let numberOfSpeakersInternal: Int?
    public var numberOfSpeakers: Int {
        numberOfSpeakersInternal ?? 1
    }
    
    public var name: String {
        return dataset ?? "Unknown"
    }
    
    public static func create(from fileURL: URL?) throws -> ModelInfo? {
        guard let fileURL else {
            return nil
        }
        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(ModelInfo.self, from: data)
    }
    
    public static var installed: ModelInfo? {
        if FileManager.default.isInstalled {
            let modelInfoJson = FileManager.Constants.jsonModelURL
            return try? create(from: modelInfoJson)
        }
        return nil
    }
    
    public static var installedModels: [ModelInfo] {
        FileManager.ModelPaths.installedModels.compactMap(\.info)
    }
    
    public var installedPath: FileManager.ModelPaths? {
        return FileManager.ModelPaths.installedModels.first { paths in
            paths.info == self
        }
    }
    
    static let separator = "-"
    public var voiceId: String {
        let components = [
            name,
            "\(language.code)",
            "\(numberOfSpeakers)"
        ]
        return components.joined(separator: Self.separator)
    }
    
    public static func installedModelInfo(for voiceId: String) -> ModelInfo? {
        let components = voiceId.split(separator: Self.separator)
        guard components.count == 3 else {
            return nil
        }
        
        let name = String(components[0])
        let languageCode = String(components[1])
        
        let numberOfSpeakersString = String(components[2]).components(separatedBy: "_").first
        return installedModels.first { model in
            return model.name == name &&
            model.language.code == languageCode &&
            numberOfSpeakersString == "\(model.numberOfSpeakers)"
        }
    }
}

extension ModelInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(piperVersion)
        hasher.combine(language)
        hasher.combine(audio)
        hasher.combine(speakers)
        hasher.combine(numberOfSpeakers)
    }
}

extension ModelInfo: Equatable {
    static public func == (lhs: ModelInfo, rhs: ModelInfo) -> Bool {
        lhs.name == rhs.name
        && lhs.piperVersion == rhs.piperVersion
        && lhs.language == rhs.language
        && lhs.audio == rhs.audio
        && lhs.speakers == rhs.speakers
        && lhs.numberOfSpeakers == rhs.numberOfSpeakers
    }
}
