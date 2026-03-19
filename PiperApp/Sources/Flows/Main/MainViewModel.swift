// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

struct MainViewModel {
    var showConnectLoadingIndicator = false
    var errorMessage: String?
    var installedModels: [FileManager.ModelPaths] = []
}
