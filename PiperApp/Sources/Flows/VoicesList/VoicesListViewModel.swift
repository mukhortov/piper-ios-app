// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

struct VoicesListViewModel {
    var showLoadingIndicator: Bool = false
    var downloadingVocieKey: String?
    var languages: [String] = []
}
