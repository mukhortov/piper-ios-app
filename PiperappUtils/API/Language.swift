// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation

public struct Language: Decodable {
    enum CodingKeys: String, CodingKey {
        case code
        case family
        case region
        case nameNative = "name_native"
        case nameEnglish = "name_english"
        case countryEnglish = "country_english"
    }
    public let code: String
    public let family: String
    public let region: String
    public let nameNative: String
    public let nameEnglish: String
    public let countryEnglish: String
}
