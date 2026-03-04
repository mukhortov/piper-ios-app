// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import Combine
import PiperAppUtils
import UIKit

class MainHostModel: @unchecked Sendable, ObservableObject {
    @Published var viewModel: MainViewModel
    private var statusObservation: AnyCancellable?
    private var playingCancellable: AnyCancellable?
    let piper: PiperManager
    
    init(piper: PiperManager) {
        self.piper = piper
        let isInstalled = piper.isVoiceInstalled
        let modelInfo = piper.modelInfo
        viewModel = MainViewModel(installed: isInstalled,
                                  modelInfo: modelInfo)
        updateSample()
        if isInstalled {
            connect()
            setupAudioUnitObservation()
        }
        
        playingCancellable = piper.$isPlaying.sink { [weak self] isPlaying in
            guard let self = self else {
                return
            }
            
            self.viewModel.isPlaying = isPlaying
        }
    }
    
    func connect() {
        Task {
            await self.piper.audioUnit.connect()
        }
    }
    
    func setupAudioUnitObservation() {
        statusObservation = self.piper.audioUnit.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.viewModel.showConnectLoadingIndicator = status != PiperAudioUnit.Status.connected
            }
    }
    
    func install() {
        viewModel.showInstallLoadingIndicator = true
        Task { [weak self] in
            await self?.piper.install(paths: self?.piper.modelPaths)
            await MainActor.run { [weak self] in
                self?.viewModel.installed = FileManager.default.isInstalled
                self?.viewModel.showInstallLoadingIndicator = false
            }

            self?.setupAudioUnitObservation()
        }
    }
    
    func play() {
        let demoText = viewModel.demoText
        Task { [weak self] in
            guard let self else {
                return
            }
            
            if self.viewModel.isPlaying {
                await self.piper.stopPlaying()
            } else {
                await self.piper.playSample(demoText: demoText)
            }
        }
    }
    
    func updateSample() {
        guard let sampleJSONData = NSDataAsset(name: "Samples")?.data else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let samples = try decoder.decode([String: String].self, from: sampleJSONData)
            if  let code = viewModel.modelInfo?.language.code,
                let sample = samples[code] {
                viewModel.demoText = sample
            }
        } catch {
            Log.error("Failed to decode samples: \(error)")
        }
    }
    
    func uninstall() {
        piper.unstall()
        modelDidChange()
    }
    
    func selected(files: [URL]) {
        if files.count != 2 {
            Log.error("Wrong number of files selected: \(files.count)")
            return
        }
        
        let model = files.model
        let modelJSON = files.json
        
        if model?.startAccessingSecurityScopedResource() != true {
            Log.error("Failed to access model")
            return
        }
        defer {
            model?.stopAccessingSecurityScopedResource()
        }
        
        if modelJSON?.startAccessingSecurityScopedResource() != true {
            Log.error("Failed to access JSON")
            return
        }
        defer {
            modelJSON?.stopAccessingSecurityScopedResource()
        }

        guard let paths = FileManager.ModelPaths(model: model, json: modelJSON) else {
            Log.error("Failed to find model or model JSON file")
            return
        }
        
        if ModelInfo.create(from: paths.json) == nil {
            Log.error("Failed to create ModelInfo from modelJSON")
            return
        }
        
        piper.saveToDocumentsAndInstallIfNeeded(paths: paths)
        viewModel.modelInfo = piper.modelInfo
        modelDidChange()
    }
}

extension MainHostModel: ModelChangeDelegate {
    func modelDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let isInstalled = self.piper.isVoiceInstalled
            let modelInfo = self.piper.modelInfo
            self.viewModel = MainViewModel(installed: isInstalled,
                                           modelInfo: modelInfo)
            self.updateSample()
        }
    }
}
