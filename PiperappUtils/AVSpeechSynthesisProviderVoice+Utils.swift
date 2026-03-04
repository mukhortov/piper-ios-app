// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import AVFAudio

extension AVSpeechSynthesisProviderVoice {
    public static var supportedVoices: [AVSpeechSynthesisProviderVoice] {
        guard let installedModel = ModelInfo.installed else {
            return []
        }
        
        let languageCode = "\(installedModel.language.family)-\(installedModel.language.region)"
        return [
            AVSpeechSynthesisProviderVoice(name: installedModel.dataset.capitalized,
                                           identifier: installedModel.dataset,
                                           primaryLanguages: [languageCode],
                                           supportedLanguages: [languageCode]
                                          )
        ]
    }
}
