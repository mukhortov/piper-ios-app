// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 Ihor Shevchuk

import AVFoundation

import piper_objc
import PiperAppUtils

public class PiperTTSAudioUnit: AVSpeechSynthesisProviderAudioUnit {
    private var outputBus: AUAudioUnitBus
    private var _outputBusses: AUAudioUnitBusArray!
    
    private var request: AVSpeechSynthesisProviderRequest?

    private var format: AVAudioFormat

    var piper: Piper?
    
    private var outputDataLock = os_unfair_lock_s()
    private var outputData: [Float] = []
    private var outputOffset = 0
    private var outputRecurseCallNumber = 0
    
    private let outputRecurseCallNumberMax: UInt32 = 200
    private let baseDelayMicroseconds: UInt32 = 500

    @objc override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {

        self.format = AVAudioFormat.defaultFormat!

        outputBus = try AUAudioUnitBus(format: self.format)
        try super.init(componentDescription: componentDescription, options: options)
        _outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [outputBus])
    }
    
    public override var outputBusses: AUAudioUnitBusArray {
        return _outputBusses
    }
    
    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        Log.debug("allocateRenderResources")
        if piper == nil {
            let model = FileManager.Constants.modelURL?.path()
            let config = FileManager.Constants.jsonModelURL?.path()
            piper = Piper(modelPath: model!,
                          andConfigPath: config!)
            piper?.delegate = self
        }
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        piper = nil
    }

	// MARK: - Rendering
	/*
	 NOTE:- It is only safe to use Swift for audio rendering in this case, as Audio Unit Speech Extensions process offline.
	 (Swift is not usually recommended for processing on the realtime audio thread)
	 */
    public override var internalRenderBlock: AUInternalRenderBlock { self.performRender }

    // swiftlint:disable:next function_parameter_count
    private func performRender(
      actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
      timestamp: UnsafePointer<AudioTimeStamp>,
      frameCount: AUAudioFrameCount,
      outputBusNumber: Int,
      outputAudioBufferList: UnsafeMutablePointer<AudioBufferList>,
      renderEvents: UnsafePointer<AURenderEvent>?,
      renderPull: AURenderPullInputBlock?
    ) -> AUAudioUnitStatus {
        return doPerformRender(actionFlags: actionFlags, timestamp: timestamp, frameCount: frameCount, outputBusNumber: outputBusNumber, outputAudioBufferList: outputAudioBufferList, renderEvents: renderEvents, renderPull: renderPull)
    }
    
    // swiftlint:disable:next function_parameter_count function_body_length
    private func doPerformRender(
      actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
      timestamp: UnsafePointer<AudioTimeStamp>,
      frameCount: AUAudioFrameCount,
      outputBusNumber: Int,
      outputAudioBufferList: UnsafeMutablePointer<AudioBufferList>,
      renderEvents: UnsafePointer<AURenderEvent>?,
      renderPull: AURenderPullInputBlock?
    ) -> AUAudioUnitStatus {
        
        guard let piper = self.piper else {
            Log.error("Piper is nil while request for rendering came.")
            return kAudioComponentErr_InstanceInvalidated
        }
        
        if request == nil {
            Log.debug(type: .synthesizer, "Request is nil. Completed rendering")
            actionFlags.pointee = .offlineUnitRenderAction_Complete
            self.cleanUp()
            return noErr
        }
        
        let intFrameCount = Int(frameCount)
        let outputDataCount: Int
        let currentOutputOffsetSnapshot: Int
        os_unfair_lock_lock(&outputDataLock)
        outputDataCount = outputData.count
        currentOutputOffsetSnapshot = outputOffset
        os_unfair_lock_unlock(&outputDataLock)

        let coutOfDataAvailable = max(0, min(outputDataCount - currentOutputOffsetSnapshot, intFrameCount))

        if coutOfDataAvailable < intFrameCount {
            let completedRendering = piper.completed()
            if completedRendering && coutOfDataAvailable <= 0 || request == nil {
                Log.debug(type: .synthesizer, "Completed rendering")
                actionFlags.pointee = .offlineUnitRenderAction_Complete
                self.cleanUp()
                return noErr
            }
            
            outputRecurseCallNumber += 1
            if outputRecurseCallNumber < outputRecurseCallNumberMax && !completedRendering {
                Log.error(type: .synthesizer, "Rendering in progress no data. Trying one more time: \(outputRecurseCallNumber)")
                pauseUntil(maxDelayFactor: outputRecurseCallNumberMax) {
                    piper.completed()
                }
                return doPerformRender(actionFlags: actionFlags, timestamp: timestamp, frameCount: frameCount, outputBusNumber: outputBusNumber, outputAudioBufferList: outputAudioBufferList, renderEvents: renderEvents, renderPull: renderPull)
            }
            Log.error(type: .synthesizer, "Tryied \(outputRecurseCallNumber), without luck. Returning what have currently")
        }
        
        outputRecurseCallNumber = 0
        
        outputAudioBufferList.pointee.mNumberBuffers = 1
        var unsafeBuffer = UnsafeMutableAudioBufferListPointer(outputAudioBufferList)[0]
        let frames = unsafeBuffer.mData!.assumingMemoryBound(to: Float32.self)
        frames.update(repeating: 0, count: intFrameCount)
        unsafeBuffer.mNumberChannels = 1
        unsafeBuffer.mDataByteSize = UInt32(coutOfDataAvailable * MemoryLayout<Float32>.size)

        let framesRequested = coutOfDataAvailable

        os_unfair_lock_lock(&outputDataLock)

        let currentOutputOffset = outputOffset
        let totalAvailableSamples = outputData.count

        if currentOutputOffset >= 0,
            currentOutputOffset < totalAvailableSamples,
            (currentOutputOffset + framesRequested) <= totalAvailableSamples {

            outputData.withUnsafeBufferPointer { buf in
                guard let base = buf.baseAddress else { return }
                frames.update(from: base.advanced(by: currentOutputOffset), count: framesRequested)
            }

            outputOffset = currentOutputOffset + framesRequested
        }

        os_unfair_lock_unlock(&outputDataLock)

        actionFlags.pointee = .offlineUnitRenderAction_Render
#if DEBUG
        Log.debug(type: .synthesizer, "Rendered: \(coutOfDataAvailable) outputOffset: \(outputOffset).")
#endif
        return noErr
    }

    public override func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
        os_unfair_lock_lock(&outputDataLock)
        Log.debug("synthesizeSpeechRequest \(speechRequest.ssmlRepresentation)")
        self.request = speechRequest
        os_unfair_lock_unlock(&outputDataLock)
        piper?.cancel()
        piper?.synthesizeSSML(speechRequest.ssmlRepresentation)
    }
    
    public override func cancelSpeechRequest() {
        Log.debug("cancelSpeechRequest")
        cleanUp()
    }

    func cleanUp() {
        Log.debug("cleanUp request:\(request?.ssmlRepresentation ?? "nil")")
        request = nil
        piper?.cancel()
        os_unfair_lock_lock(&outputDataLock)
        outputData = []
        outputOffset = 0
        os_unfair_lock_unlock(&outputDataLock)
    }
    
    private func pauseUntil(maxDelayFactor: UInt32, or condition: @escaping () -> Bool) {
        let maxDelaySeconds = Double(baseDelayMicroseconds * maxDelayFactor) / 1_000_000
        let checkIntervalSeconds = maxDelaySeconds / 5.0

        let startTime = Date()
        
        while !condition() && Date().timeIntervalSince(startTime) < maxDelaySeconds {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(checkIntervalSeconds))
        }
    }

    public override var speechVoices: [AVSpeechSynthesisProviderVoice] {
        get {
            return AVSpeechSynthesisProviderVoice.supportedVoices
        }
        set { }
    }
    
    public override func messageChannel(for channelName: String) -> AUMessageChannel {
        Log.debug("Creating message channel for \(channelName)")
        return PiperMessageChannel(delegate: self)
    }
}

extension PiperTTSAudioUnit: PiperDelegate {
    public func piperDidReceiveSamples(_ samples: UnsafePointer<Float>, withSize count: Int) {
        let buf = UnsafeBufferPointer(start: samples, count: count)
        os_unfair_lock_lock(&outputDataLock)
        outputData.append(contentsOf: buf)
        os_unfair_lock_unlock(&outputDataLock)
    }
}

extension PiperTTSAudioUnit: PiperMessageChannelDelegate {
    var isSyntehizerRunning: Bool {
        os_unfair_lock_lock(&outputDataLock)
        let result = request != nil
        os_unfair_lock_unlock(&outputDataLock)
        return result
    }
}
