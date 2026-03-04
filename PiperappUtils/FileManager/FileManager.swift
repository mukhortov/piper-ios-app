//
//  FileManager.swift
//  Piper
//
//  Created by Ihor Shevchuk on 2026-02-21.
//  Copyright © 2026 Ihor Shevchuk. All rights reserved.
//

import Foundation

extension FileManager {
    public struct ModelPaths {
        public let model: URL
        public let json: URL
        public init?(model: URL?, json: URL?) {
            guard let model, let json else {
                return nil
            }
            self.model = model
            self.json = json
        }
        
        public var exist: Bool {
            return FileManager.default.fileExists(atPath: model.path) &&
            FileManager.default.fileExists(atPath: json.path)
        }
        
        public static var engine: ModelPaths? {
            return ModelPaths(model: FileManager.Constants.modelURL,
                              json: FileManager.Constants.jsonModelURL)
        }
    }
    
    public var isInstalled: Bool {
        guard let paths = ModelPaths.engine else {
            return false
        }
        return paths.exist
    }
}
