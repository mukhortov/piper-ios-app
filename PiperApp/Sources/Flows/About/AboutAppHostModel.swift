// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import Combine
import PiperAppUtils
import AVFoundation

class AboutAppHostModel: @unchecked Sendable, ObservableObject {
    @Published var viewModel: AboutAppViewModel
    let piper: PiperManager
    
    @MainActor
    init(piper: PiperManager) {
        self.piper = piper
        viewModel = AboutAppViewModel(appVersion: Bundle.main.applicationVersion,
                                      connectionStatus: piper.audioUnit.status.string)
    }
}
