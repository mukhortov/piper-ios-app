// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation

extension FileManager {
    public struct ModelPaths {
        public let model: URL
        public let json: URL
        public var info: ModelInfo? {
            return try? ModelInfo.create(from: json)
        }
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
        
        public var modelFolder: URL? {
            if self == ModelPaths.engine {
                return nil
            }
            
            let modelParent = model.deletingLastPathComponent()
            let jsonParent = json.deletingLastPathComponent()
            if modelParent == jsonParent
                && modelParent.deletingLastPathComponent() == Constants.modelsFolderURL {
                return modelParent
            }
            return nil
        }
        
        public static var engine: ModelPaths? {
            return ModelPaths(model: FileManager.Constants.modelURL,
                              json: FileManager.Constants.jsonModelURL)
        }
        
        public static var installNew: ModelPaths? {
            guard let modelsFolder = FileManager.Constants.modelsFolderURL else {
                return nil
            }
            let installNewFolder = modelsFolder.appendingPathComponent(UUID().uuidString)
            return ModelPaths(model: installNewFolder.appendingPathComponent(PiperAppUtils.Constants.modelFileNameWithExtension),
                              json: installNewFolder.appendingPathComponent(PiperAppUtils.Constants.modelJSONFileNameWithExtension))
        }
        
        public var isInstalled: Bool {
            if self == ModelPaths.engine && exist {
                return true
            }
            
            return ModelPaths.installed.contains(self)
        }
        
        @FileBacked<[ModelPaths]>(default: [], urlProvider: {
            Constants.modelsJsonURL
        }) static var installed
        
        public static var installedModels: [ModelPaths] {
            get {
                var result = Set<ModelPaths>()
                if let legacy = ModelPaths.engine,
                    legacy.exist {
                    result.insert(legacy)
                }
                result.formUnion(installed)
                return Array(result)
            }
            set {
                self.installed = newValue
            }
        }
    }
    
    enum Error: Swift.Error {
        case nilModelFolderURL
    }
    
    public var isInstalled: Bool {
        guard let paths = ModelPaths.engine else {
            return false
        }
        return paths.exist
    }
    
    public func createModelPathsFolder(paths: ModelPaths) throws {
        guard let folder = paths.modelFolder else {
            throw Error.nilModelFolderURL
        }
        try createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
    }
}

extension FileManager.ModelPaths: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.model == rhs.model &&
               lhs.json == rhs.json &&
               lhs.exist == rhs.exist &&
               lhs.info == rhs.info
    }
}

extension FileManager.ModelPaths: Codable {
    enum CodingKeys: String, CodingKey {
        case model
        case json
    }
}

extension FileManager.ModelPaths: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(model)
        hasher.combine(json)
        hasher.combine(exist)
        hasher.combine(info)
    }
}
