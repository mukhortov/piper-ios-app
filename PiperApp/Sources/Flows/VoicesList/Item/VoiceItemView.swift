// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import SwiftUI
import PiperAppUtils

struct VoiceItemView: View {
    
    @StateObject var hostModel: VoiceItemHostModel
    var voice: Voice {
        hostModel.viewModel.voice
    }
    
    var body: some View {
        let voiceTitle = voice.name.capitalized + " " + voice.quality + " "
        Button {
            hostModel.download(voice: voice)
        } label: {
            HStack {
                VStack {
                    HStack {
                        Text(voiceTitle)
                            .font(.body)
                        Spacer()
                    }
                    HStack {
                        Text(voice.voiceSizeString)
                            .font(.footnote)
                        Spacer()
                    }
                }
                Spacer()
                if hostModel.isInstalled(voice) {
                    Image(systemName: "checkmark")
                        .accessibilityLabel("downloaded")
                } else if hostModel.viewModel.isDownloading {
                    ProgressView()
                        .accessibilityLabel("downloading")
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .accessibilityLabel("download_voice")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
