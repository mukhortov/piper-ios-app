// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import SwiftUI

@main
struct PiperApp: App {
    let mainModel = MainHostModel(piper: AppManager.shared.piper)
    var body: some Scene {
        WindowGroup {
            MainView(hostModel: mainModel)
        }
    }
}
