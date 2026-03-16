// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import SwiftUI
import PiperAppUtils

struct VoiceItemView: View {
    
    @StateObject var hostModel: VoiceItemHostModel
    var voice: Voice {
        hostModel.viewModel.voice
    }
    @State var unstallConfirmationShown: Bool = false
    
    @ViewBuilder
    private func download() -> some View {
        let size = 50.0
        HStack {
            if hostModel.isInstalled(voice) {
                Button {
                    unstallConfirmationShown.toggle()
                } label: {
                    Image(systemName: "trash")
                        .imageScale(.large)
                        .accessibilityLabel("uninstall_voice")
                        .frame(width: size, height: size)
                }
                .buttonStyle(PlainButtonStyle())
                .alert("uninstall_voice", isPresented: $unstallConfirmationShown) {
                    Button("uninstall_button", role: .destructive) {
                        hostModel.remove(voice: voice)
                    }
                    Button("cancel", role: .cancel) {
                        unstallConfirmationShown.toggle()
                    }
                }
            } else if hostModel.viewModel.isDownloading {
                CircularProgressView(progress: hostModel.viewModel.downloadProgress)
                    .frame(width: size, height: size)
                    .accessibilityElement()
                    .accessibilityLabel("downloading")
                    .accessibilityValue(String(localized: "voice_loading_progress_\(hostModel.viewModel.downloadProgress * 100)"))
            } else {
                Button {
                    hostModel.download(voice: voice)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .imageScale(.large)
                        .accessibilityLabel("download_voice")
                        .frame(width: size, height: size)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
       
    }
    
    var body: some View {
        let voiceTitle = voice.name.capitalized + " " + voice.quality + " "
        HStack {
            Spacer()
                .frame(width: 10)
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
            .accessibilityElement(children: .combine)
            Spacer()
            download()
        }
    }
}
