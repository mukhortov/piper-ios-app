// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import Combine
import PiperAppUtils
import AVFoundation

class AboutAppHostModel: @unchecked Sendable, ObservableObject {
    @Published var viewModel: AboutAppViewModel
    
    @MainActor
    init(piper: PiperManager) {
        viewModel = AboutAppViewModel(appVersion: Bundle.main.applicationVersion,
                                      connectionStatus: piper.audioUnit.status.string)
    }
}
