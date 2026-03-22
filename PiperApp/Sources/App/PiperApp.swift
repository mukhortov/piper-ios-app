// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import SwiftUI

@main
struct PiperApp: App {
    
#if os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: ApplicationDelegate
#elseif os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: ApplicationDelegate
#endif
    
    @ViewBuilder
    var mainContent: some View {
        MainView(hostModel: mainModel)
            .frame(minWidth: 400, minHeight: 300)
    }
    
    let mainModel = MainHostModel(piper: AppManager.shared.piper)
    var body: some Scene {
        #if os(macOS)
        Window("piper_app_name".localized, id: "main") {
            mainContent
        }
        #elseif os(iOS)
        WindowGroup {
            mainContent
        }
        #endif
    }
}
