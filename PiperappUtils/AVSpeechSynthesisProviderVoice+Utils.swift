// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import AVFAudio

extension AVSpeechSynthesisProviderVoice {
    public static var supportedVoices: [AVSpeechSynthesisProviderVoice] {
        guard let installedModel = ModelInfo.installed else {
            return []
        }
        
        let languageCode = "\(installedModel.language.family)-\(installedModel.language.region)"
        
        if installedModel.numberOfSpeakers <= 1 || installedModel.speakers.isEmpty {
            return [
                AVSpeechSynthesisProviderVoice(name: installedModel.dataset.capitalized,
                                               identifier: installedModel.dataset,
                                               primaryLanguages: [languageCode],
                                               supportedLanguages: [languageCode]
                                              )
            ]
        }
        
        return installedModel.speakers.map { (name, id) in
            AVSpeechSynthesisProviderVoice(name: name.capitalized,
                                           identifier: "\(name)_\(id)",
                                           primaryLanguages: [languageCode],
                                           supportedLanguages: [languageCode]
                                          )
        }
    }
}
