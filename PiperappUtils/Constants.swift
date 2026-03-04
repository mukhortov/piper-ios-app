// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import UniformTypeIdentifiers

public enum Constants {
    public static let modelFileName = "model"
    public static let modelExtensiom = "onnx"
    public static let jsonModelExtensiom = "json"
    public static var modelFileNameWithExtension: String {
        return "\(modelFileName).\(modelExtensiom)"
    }
    public static var modelJSONFileNameWithExtension: String {
        return "\(modelFileNameWithExtension).\(jsonModelExtensiom)"
    }
    
    public static let jsonUTI: UTType = .json
    public static let modelUTI: UTType = .init(filenameExtension: modelExtensiom) ?? .item
}
