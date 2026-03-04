// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import AVFoundation

extension AVAudioFormat {
    public static var defaultFormat: AVAudioFormat? {
        let sampleRate = if let installed = ModelInfo.installed {
            installed.audio.sampleRate
        } else {
            16000.0
        }
        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: true)
    }
}
