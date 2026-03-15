// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import SwiftUI
import PiperAppUtils

struct VoicesListView: View {
    
    @StateObject var hostModel: VoicesListHostModel
    
    @ViewBuilder
    func viewForVoiceItem(_ voice: Voice) -> some View {
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
                } else if voice.key == hostModel.viewModel.downloadingVocieKey {
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
    
    @ViewBuilder
    func voicesList(for language: String, title: String) -> some View {
        NavigationStack {
            if let voices = hostModel.languages[language]?.sorted(by: { voice1, voice2 in
                voice1.name < voice2.name
            }),
               !voices.isEmpty {
                List {
                    Section(content: {
                        ForEach(voices, id: \.key) { voice in
                            viewForVoiceItem(voice)
                        }
                    }, header: {
                        Text("warning_not_tested_voices")
                            .font(.footnote)
                    }, footer: {
                        Text("warning_big_voice_files")
                            .font(.footnote)
                    })
                }
            } else {
                Text("no_voices")
            }
        }
        .navigationTitle(title)
    }
    
    var body: some View {
        NavigationStack {
            if hostModel.viewModel.showLoadingIndicator {
                ProgressView()
            } else {
                List {
                    Section {
                        ForEach(hostModel.viewModel.languages, id: \.self) { language in
                            let title = Locale.current.localizedString(forIdentifier: language) ?? language
                            NavigationLink {
                                voicesList(for: language, title: title)
                            } label: {
                                Text(title)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("languages".localized)
    }
}
