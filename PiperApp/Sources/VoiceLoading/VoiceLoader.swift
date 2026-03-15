// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

class VoiceLoader {
    private enum Error: Swift.Error {
        case nilURL
        case loadingFailed
        case wrongModelInfo
    }
    private enum Constants {
        static let baseURL = "https://huggingface.co/rhasspy/piper-voices/resolve/main"
        
        static var voicesURL: URL? {
            return URL(string: "\(Constants.baseURL)/voices.json")
        }
    }
    
    private func load<Item: Decodable>(url: URL?) async throws -> Item {
        guard let url else {
            throw Error.nilURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Item.self, from: data)
    }
    
    func loadVoices() async throws -> [Voice] {
        let allVoices: [String: Voice] = try await load(url: Constants.voicesURL)
        return Array(allVoices.values)
    }
    
    func download(voice: Voice) async throws -> FileManager.ModelPaths {
        guard let modelPath = voice.modelPath,
           let jsonPath = voice.jsonPath else {
            throw Error.loadingFailed
        }
        
        guard let modelURL = URL(string: "\(Constants.baseURL)/\(modelPath)"),
              let jsonURL = URL(string: "\(Constants.baseURL)/\(jsonPath)") else {
            throw Error.nilURL
        }
        
        let (jsonLocalURL, _) = try await URLSession.shared.download(from: jsonURL)
        if (try? ModelInfo.create(from: jsonLocalURL)) == nil {
            do {
                try FileManager.default.removeItem(at: jsonLocalURL)
            } catch {
                Log.error("Failed to remove downloaded local json file: \(error)")
            }
            throw Error.wrongModelInfo
        }
        
        let (modelLocalURL, _) = try await URLSession.shared.download(from: modelURL)
        
        guard let modelPath = FileManager.ModelPaths(model: modelLocalURL, json: jsonLocalURL) else {
            throw Error.loadingFailed
        }
        
        return modelPath
    }
}
