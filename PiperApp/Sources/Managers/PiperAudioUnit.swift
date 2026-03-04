// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import Foundation
import AVFAudio
import Combine
import PiperAppUtils

class PiperAudioUnit {
    enum Status {
        case connected
        case disconnected
        case failedToConnect
        
        var string: String {
            switch self {
            case .connected:
                return "audio_unit_status_connected".localized
            case .disconnected:
                return "audio_unit_status_disconnected".localized
            case .failedToConnect:
                return "audio_unit_status_failed".localized
            }
        }
    }
    
    @MainActor @Published private(set) var status: PiperAudioUnit.Status = .disconnected
    
    private func setStatus(_ status: PiperAudioUnit.Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
    private var audioUnit: AVAudioUnit?
    private let engine = AVAudioEngine()
    private var messageChannel: AUMessageChannel?
    
    func loadAudioUnit(with description: AudioComponentDescription) async throws -> AVAudioUnit {
        try await withCheckedThrowingContinuation { continuation in
            AVAudioUnit.instantiate(with: description, options: [.loadOutOfProcess]) { audioUnit, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let audioUnit = audioUnit {
                    continuation.resume(returning: audioUnit)
                } else {
                    continuation.resume(throwing: NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_ExtensionNotFound), userInfo: [:]))
                }
            }
        }
    }
    
    func connect() async {
        Log.debug("Connecting audio unit...")
        let componentDescription = AudioComponentDescription(componentType: kAudioUnitType_SpeechSynthesizer,
                                                             componentSubType: "pipr".audioComponentOSType,
                                                             componentManufacturer: "pipr".audioComponentOSType,
                                                             componentFlags: AudioComponentFlags([.sandboxSafe, .isV3AudioUnit]).rawValue,
                                                             componentFlagsMask: AudioComponentFlags([.sandboxSafe, .isV3AudioUnit]).rawValue
                                                             )
        do {
            guard let format = AVAudioFormat.defaultFormat else {
                setStatus(.failedToConnect)
                return
            }
            let audioUnit = try await loadAudioUnit(with: componentDescription)
            
            if engine.isRunning {
                engine.stop()
            }
            self.engine.attach(audioUnit)
            self.engine.connect(audioUnit, to: engine.outputNode, format: format)
            self.engine.prepare()
            self.engine.isAutoShutdownEnabled = true
            self.messageChannel = audioUnit.auAudioUnit.messageChannel(for: "\(Self.Type.self)")
            self.audioUnit = audioUnit
            setStatus(.connected)
            Log.debug("Connected audio unit successfully.")
        } catch {
            Log.error("Failed to connect audio unit: \(error)")
            setStatus(.failedToConnect)
        }
    }
    
    func disconnect() async {
        Log.debug("Disconnecting audio unit...")
        if engine.isRunning {
            engine.stop()
        }
        self.audioUnit?.reset()
        self.audioUnit = nil
        setStatus(.disconnected)
        Log.debug("Disconnected audio unit successfully.")
    }
    
    func play(text: String) async {
        
        guard let audioUnit else {
            Log.error("Audio unit is nil. Can't play text.")
            return
        }
        
        guard let voice = AVSpeechSynthesisProviderVoice.supportedVoices.first else {
            Log.error("No supported voices. Can't play text.")
            return
        }
        
        let auAudioUnit = audioUnit.auAudioUnit
        if !auAudioUnit.renderResourcesAllocated {
            try? auAudioUnit.allocateRenderResources()
        }
        
        try? self.engine.start()
        let request = AVSpeechSynthesisProviderRequest(
          ssmlRepresentation: "<speak>\(text)</speak>",
          voice: voice
        )
        
        if auAudioUnit.responds(to: #selector(AVSpeechSynthesisProviderAudioUnit.synthesizeSpeechRequest(_:))) {
            auAudioUnit.perform(#selector(AVSpeechSynthesisProviderAudioUnit.synthesizeSpeechRequest(_:)), with: request)
        }
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return
            }
            Task { [weak self] in
                guard let self else {
                    return
                }
                while self.isSynthesizing {
                    try? await Task.sleep(for: .seconds(1.0))
                }
                continuation.resume()
            }
        }
    }
    
    func stop() {
        audioUnit?.engine?.stop()
        if let auAudioUnit = audioUnit?.auAudioUnit {
            if auAudioUnit.responds(to: #selector(AVSpeechSynthesisProviderAudioUnit.cancelSpeechRequest)) {
                auAudioUnit.perform(#selector(AVSpeechSynthesisProviderAudioUnit.cancelSpeechRequest), with: nil)
            }
        }
    }
    
    var isSynthesizing: Bool {
        guard let messageChannel else {
            return false
        }
        guard let responseObject = messageChannel.callAudioUnit?([MessageChannelKeys.kIsSyntehizerRunning: false]) else {
            return false
        }
        
        return responseObject[MessageChannelKeys.kIsSyntehizerRunning] as? Bool ?? false
    }
}
