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
         loader: VoiceLoader = AppManager.shared.loader,
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
                let modelPath = try await self.loader.download(voice: voice)
                await self.piper.install(paths: modelPath)
                try? FileManager.default.removeItem(at: modelPath.json)
                try? FileManager.default.removeItem(at: modelPath.model)
                self.delegate?.modelDidChange()
            } catch {
                Log.error("Failed to download voices: \(error)")
            }
            
            await MainActor.run {
                self.viewModel.isDownloading = false
            }
        }
    }
    
    func isInstalled(_ voice: Voice) -> Bool {
        self.piper.installedVoices.contains { modelPath in
            guard let modelInfo = modelPath.info else {
                return false
            }
            return modelInfo.dataset == voice.name && modelInfo.audio.quality == voice.quality
        }
    }
}
