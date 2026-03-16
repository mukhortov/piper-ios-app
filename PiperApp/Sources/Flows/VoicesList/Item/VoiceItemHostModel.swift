// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import Combine
import PiperAppUtils

class VoiceItemHostModel: @unchecked Sendable, ObservableObject {
    @Published var viewModel: VoiceItemViewModel
    let piper: PiperManager
    let loader: VoiceLoader
    var languages: [String: [Voice]] = [:]
    weak var delegate: ModelChangeDelegate?
    init(piper: PiperManager,
         loader: VoiceLoader,
         voice: Voice,
         delegate: ModelChangeDelegate?) {
        viewModel = VoiceItemViewModel(voice: voice)
        self.piper = piper
        self.loader = loader
        self.delegate = delegate
    }
    
    func download(voice: Voice) {
        Task { [weak self] in
            guard let self else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.viewModel.isDownloading = true
            }
            do {
                for try await event in loader.download(voice: voice) {
                    
                    switch event {
                        
                    case .progress(let value):
                        await MainActor.run { [weak self] in
                            guard let self else { return }
                            self.viewModel.downloadProgress = value
                        }
                        
                    case .finished(let modelPath):
                        await self.piper.install(paths: modelPath)
                        try? FileManager.default.removeItem(at: modelPath.json)
                        try? FileManager.default.removeItem(at: modelPath.model)
                        self.delegate?.modelDidChange()
                    }
                }
            } catch {
                Log.error("Failed to download voices: \(error)")
            }
            
            await MainActor.run {
                self.viewModel.downloadProgress = 0.0
                self.viewModel.isDownloading = false
            }
        }
    }
    
    func remove(voice: Voice) {
        guard let installed = installed(voice) else {
            return
        }
        piper.unstall(paths: installed)
        delegate?.modelDidChange()
    }
    
    func isInstalled(_ voice: Voice) -> Bool {
        return installed(voice) != nil
    }
    
    func installed(_ voice: Voice) -> FileManager.ModelPaths? {
        self.piper.installedVoices.first { modelPath in
            guard let modelInfo = try? modelPath.info else {
                return false
            }
            return modelInfo.dataset == voice.name && modelInfo.audio.quality == voice.quality
        }
    }
}
