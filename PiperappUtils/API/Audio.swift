// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation

public struct Audio: Decodable {
    enum CodingKeys: String, CodingKey {
        case sampleRate = "sample_rate"
        case quality
    }
    public let sampleRate: Double
    public let quality: String
}
