// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation

public struct ModelInfo: Decodable {
    enum CodingKeys: String, CodingKey {
        case dataset
        case piperVersion = "piper_version"
        case language
        case audio
    }
    
    public let dataset: String
    public let piperVersion: String
    public let language: Language
    public let audio: Audio
    
    public static func create(from fileURL: URL?) -> ModelInfo? {
        guard let fileURL else {
            return nil
        }
       
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let jsonDecoder = JSONDecoder()
            return try jsonDecoder.decode(ModelInfo.self, from: data)
        } catch {
            Log.error("Failed to decode ModelInfo from file: \(fileURL.path())")
        }
        return nil
    }
    
    public static var installed: ModelInfo? {
        if FileManager.default.isInstalled {
            let modelInfoJson = FileManager.Constants.jsonModelURL
            return create(from: modelInfoJson)
        }
        return nil
    }
}
