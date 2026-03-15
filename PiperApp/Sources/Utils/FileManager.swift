// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils

extension FileManager {
    enum InstallError: Swift.Error {
        case invalidSourceFiles
        case invalidDestinationURLs
        case cantParseModelInfo
    }
    
    func install(paths: ModelPaths?) throws {
        guard let paths else {
            throw InstallError.invalidSourceFiles
        }
        
        guard let destination = ModelPaths.installNew else {
            throw InstallError.invalidDestinationURLs
        }
        
        guard let info = paths.info else {
            throw InstallError.cantParseModelInfo
        }
        
        do {
            if let installedPath = info.installedPath {
                try uninstall(paths: installedPath)
            }
        } catch {
            Log.debug("Error happened while uninstalling. Error: \(error)")
        }
        
        let fileManager = FileManager.default
        try fileManager.createModelPathsFolder(paths: destination)
        try fileManager.copyItem(at: paths.json, to: destination.json)
        try fileManager.copyItem(at: paths.model, to: destination.model)
        var installedModels = FileManager.ModelPaths.installedModels
        installedModels.append(destination)
        FileManager.ModelPaths.installedModels = installedModels
    }
    
    func uninstall(paths: ModelPaths?) throws {
        
        guard let installed = paths else {
            throw InstallError.invalidDestinationURLs
        }
        
        var installedModels = FileManager.ModelPaths.installedModels
        installedModels.removeAll(where: { path in
            path == paths
        })
        FileManager.ModelPaths.installedModels = installedModels
        let fileManager = FileManager.default
        try fileManager.removeItem(at: installed.model)
        try fileManager.removeItem(at: installed.json)
        
        if let modelFolder = installed.modelFolder {
            try fileManager.removeItem(at: modelFolder)
        }
    }
}

extension FileManager.ModelPaths {
    var modelTitle: String {
        guard let modelInfo = info else {
            return "Unknown"
        }
        
        return "\(modelInfo.name.capitalized) \(modelInfo.language.code.localizedLanguageFromCode)"
    }
}
