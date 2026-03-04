// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

extension FileManager {
    enum InstallError: Swift.Error {
        case invalidSourceFiles
        case invalidDestinationURLs
    }
    
    func install(paths: ModelPaths?) throws {
        guard let paths else {
            throw InstallError.invalidSourceFiles
        }
        
        guard let destination = ModelPaths.engine else {
            throw InstallError.invalidDestinationURLs
        }
        
        do {
           try uninstall(paths: destination)
        } catch {
            Log.debug("Error happened while uninstalling. Error: \(error)")
        }
        
        let fileManager = FileManager.default
        try fileManager.copyItem(at: paths.model, to: destination.model)
        try fileManager.copyItem(at: paths.json, to: destination.json)
    }
    
    func uninstall(paths: ModelPaths?) throws {
        
        guard let installed = ModelPaths.engine else {
            throw InstallError.invalidDestinationURLs
        }
        
        let fileManager = FileManager.default
        try fileManager.removeItem(at: installed.model)
        try fileManager.removeItem(at: installed.json)
    }
    
    func saveToDocuments(paths: ModelPaths) throws {
        guard let documents = FileManager.ModelPaths.documents else {
            throw InstallError.invalidDestinationURLs
        }
        
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: documents.model)
            try fileManager.removeItem(at: documents.json)
        } catch {
            Log.debug("Error happened while removing old files. Error: \(error)")
        }
        
        try fileManager.copyItem(at: paths.model, to: documents.model)
        try fileManager.copyItem(at: paths.json, to: documents.json)
    }
}

extension FileManager.Constants {
    private static var documentsURL: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    static var modelDocumentsURL: URL? {
        return documentsURL?.appendingPathComponent(PiperAppUtils.Constants.modelFileNameWithExtension)
    }
    
    static var jsonModelDocumentsURL: URL? {
        return documentsURL?.appendingPathComponent(PiperAppUtils.Constants.modelJSONFileNameWithExtension)
    }
}

extension FileManager.ModelPaths {
    static var documents: FileManager.ModelPaths? {
        return FileManager.ModelPaths(model: FileManager.Constants.modelDocumentsURL,
                                      json: FileManager.Constants.jsonModelDocumentsURL)
    }
}
