// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

extension Bundle {
    
    var modelPaths: FileManager.ModelPaths? {
        return .init(model: modelURL, json: modelJSONURL)
    }

    var modelURL: URL? {
        return url(forResource: Constants.modelFileName, withExtension: Constants.modelExtensiom)
    }
    
    var modelJSONURL: URL? {
        return url(forResource: Constants.modelFileNameWithExtension, withExtension: Constants.jsonModelExtensiom)
    }
    
    var applicationVersion: String {
        let version = "\(infoDictionary?["CFBundleShortVersionString"] ?? "unknown").\(infoDictionary?["CFBundleVersion"] ?? "unknown")"
        return version.replacingOccurrences(of: "$BUILD_NUMBER", with: "1234")
    }
}
