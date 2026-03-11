// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import PiperAppUtils
import AVFoundation

class PiperManager {
    var isVoiceInstalled: Bool {
        FileManager.default.isInstalled
    }
    
    var installedModelInfo: ModelInfo? {
        if !isVoiceInstalled {
            return nil
        }
        return ModelInfo.installed
    }
    
    var modelPaths: FileManager.ModelPaths? {
        if let documentsPaths = FileManager.ModelPaths.documents,
           documentsPaths.exist {
            return documentsPaths
        }
        return Bundle.main.modelPaths
    }
    
    var modelInfo: ModelInfo? {
        if let installedModelInfo = installedModelInfo {
            return installedModelInfo
        }
        
        return ModelInfo.create(from: modelPaths?.json)
    }
    
    @Published var isPlaying: Bool = false
    @MainActor
    func setIsPlaying(_ isPlaying: Bool) {
        self.isPlaying = isPlaying
    }
    let audioUnit = PiperAudioUnit()
    private var syntheser: SpeechSynthesizer?
    
#if os(iOS)
    func activatePlaybackMode() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch let error {
            Log.error("Error happened during activating playback. Error:\(error)")
        }
    }
    
    func setAudioSession(active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch let error {
            Log.error("Error happened during setting audio session active status:\(active)  Error:\(error)")
        }
    }
#endif
    
    func playSample(demoText: String,
                    speakerId: Int) async {
#if os(iOS)
        activatePlaybackMode()
        setAudioSession(active: true)
#endif
        await setIsPlaying(true)
        if isVoiceInstalled {
            let voiceIdentifer = "dev.ihor-shevchuk.piperapp.pipertts.\(modelInfo?.dataset.lowercased() ?? "")_\(speakerId)"
            if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifer) {
                syntheser = SpeechSynthesizer()
                await syntheser?.speak(demoText, voice: voice)
            } else {
                await audioUnit.play(text: demoText,
                                     speakerId: speakerId)
            }
        }
        
        await stopPlaying()
    }
    
    func stopPlaying() async {
        setAudioSession(active: false)
        syntheser?.stop()
        syntheser = nil
        audioUnit.stop()
        await setIsPlaying(false)
    }
    
    func install(paths: FileManager.ModelPaths?) async {
        do {
            await audioUnit.disconnect()
            try FileManager.default.install(paths: paths)
            AVSpeechSynthesisProviderVoice.updateSpeechVoices()
            await audioUnit.connect()
        } catch {
            Log.error("Error happened during installing. Error:\(error)")
        }
    }
    
    func unstall() {
        guard let installedPath = FileManager.ModelPaths.engine else {
            Log.debug("Nothing to uninstall")
            return
        }
        
        do {
            try FileManager.default.uninstall(paths: installedPath)
            AVSpeechSynthesisProviderVoice.updateSpeechVoices()
        } catch {
            Log.error("Error happened during uninstalling. Error:\(error)")
        }
    }
    
    func saveToDocumentsAndInstallIfNeeded(paths: FileManager.ModelPaths) {
        do {
            try FileManager.default.saveToDocuments(paths: paths)
            if isVoiceInstalled {
                Task { [weak self] in
                    await self?.install(paths: paths)
                }
            }
        } catch {
            Log.error("Error happened during saving to Documents. Error:\(error)")
        }
    }
}
