// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

struct MainViewModel {
    var showInstallLoadingIndicator = false
    var showConnectLoadingIndicator = false
    var showHelp: Bool = false
    var installed: Bool
    var demoText: String = "A rainbow is a meteorological phenomenon that is caused by reflection, refraction and dispersion of light in water droplets resulting in a spectrum of light appearing in the sky."
    var errorMessage: String?
    var modelInfo: ModelInfo?
    var isPlaying: Bool = false
    var selectedSpeaker: Int = 0
}
