// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

struct Voice: Decodable {
    let key: String
    let name: String
    let quality: String
    let language: PiperAppUtils.Language
    let files: [String: VoiceFile]
    private var voiceSize: Int {
        return files.values.reduce(into: 0) { $0 += $1.size_bytes }
    }
    var voiceSizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(voiceSize), countStyle: .binary)
    }
    var modelPath: String? {
        Array(files.keys).model
    }
    var jsonPath: String? {
        Array(files.keys).json
    }
}
