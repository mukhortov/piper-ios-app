// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import Combine
import PiperAppUtils

class VoicesListHostModel: @unchecked Sendable, ObservableObject {
    @Published var viewModel: VoicesListViewModel
    let piper: PiperManager
    let loader: VoiceLoader
    var languages: [String: [Voice]] = [:]
    weak var delegate: ModelChangeDelegate?
    
    init(piper: PiperManager,
         loader: VoiceLoader = AppManager.shared.loader,
         delegate: ModelChangeDelegate?) {
        viewModel = VoicesListViewModel()
        self.piper = piper
        self.loader = loader
        self.delegate = delegate
        loadVoices()
    }
    
    func loadVoices() {
        Task {
            await MainActor.run {
                self.viewModel.showLoadingIndicator = true
            }
            
            await withTaskGroup(of: Void.self) { _ in
                do {
                    let voices = try await self.loader.loadVoices()
                    self.languages = Dictionary(grouping: voices) { voice in
                        voice.language.code
                    }
                    await MainActor.run {
                        self.viewModel.languages = Array(self.languages.keys).sorted(by: { lang1, lang2 in
                            return lang1.localizedLanguageFromCode < lang2.localizedLanguageFromCode
                        })
                    }
                } catch {
                    Log.error("Failed to load voices: \(error)")
                }
            }
            
            await MainActor.run {
                self.viewModel.showLoadingIndicator = false
            }
        }
    }
    
    func download(voice: Voice) {
        Task {
            await MainActor.run {
                self.viewModel.downloadingVocieKey = voice.key
            }
            
            do {
                let modelPath = try await self.loader.download(voice: voice)
                self.piper.saveToDocumentsAndInstallIfNeeded(paths: modelPath)
                try? FileManager.default.removeItem(at: modelPath.json)
                try? FileManager.default.removeItem(at: modelPath.model)
                self.delegate?.modelDidChange()
            } catch {
                Log.error("Failed to download voices: \(error)")
            }
            
            await MainActor.run {
                self.viewModel.downloadingVocieKey = nil
            }
        }
    }
    
    func isSavedToDocuments(_ voice: Voice) -> Bool {
        guard let modelInfo = self.piper.modelInfo else {
            return false
        }
        return modelInfo.dataset == voice.name && modelInfo.audio.quality == voice.quality
    }
}
