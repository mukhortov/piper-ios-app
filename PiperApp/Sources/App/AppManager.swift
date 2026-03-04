// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

class AppManager {
    static let shared = AppManager()
    let piper = PiperManager()
    lazy var loader = VoiceLoader()
}
