// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Ihor Shevchuk

import SwiftUI
import PiperAppUtils

struct MainView: View {
    
    @StateObject var hostModel: MainHostModel
    @State var showAboutModalView = false
    
    @ViewBuilder
    func toolBarButtonView(imageName: String,
                           accessibilityLabel: String,
                           bindingVar: Binding<Bool>) -> some View {
        Button {
            bindingVar.wrappedValue.toggle()
        } label: {
            Image(systemName: imageName)
        }
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityAddTraits(.isButton)
    }
    
    @ViewBuilder
    func aboutButtonView() -> some View {
        toolBarButtonView(imageName: "info.circle",
                          accessibilityLabel: String(localized: "about_app"),
                          bindingVar: $showAboutModalView)
    }
    
    @ViewBuilder
    func helpButtonView() -> some View {
        toolBarButtonView(imageName: "questionmark.circle",
                          accessibilityLabel: String(localized: "app_help_title"),
                          bindingVar: $hostModel.viewModel.showHelp)
    }
    
    @ViewBuilder
    private func buttonImageView(systemName: String) -> some View {
        Image(systemName: systemName)
            .imageScale(.large)
            .foregroundColor(.accentColor)
    }
    
    @ViewBuilder
    func playSampleView() -> some View {
        Section {
            if !hostModel.viewModel.showConnectLoadingIndicator {
                Button {
                    hostModel.play()
                } label: {
                    CenteredContent {
                        if hostModel.viewModel.isPlaying {
                            buttonImageView(systemName: "stop")
                            Text("stop")
                        } else {
                            buttonImageView(systemName: "play")
                            Text("play_sample")
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0
                }
            }
            if hostModel.piper.audioUnit.status != .connected && hostModel.viewModel.installed {
                Button {
                    hostModel.connect()
                } label: {
                    CenteredContent {
                        if hostModel.viewModel.showConnectLoadingIndicator {
                            CenteredContent {
                                ProgressView()
                            }
                        } else {
                            Text("connect")
                        }
                    }
                }
            }
            
            if let modelInfo = hostModel.viewModel.modelInfo {
                if !modelInfo.speakers.isEmpty {
                    Picker("speaker".localized, selection: $hostModel.viewModel.selectedSpeaker) {
                        ForEach(modelInfo.speakers.keys.sorted(), id: \.self) { speakerKey in
                            Text(speakerKey.capitalized)
                                .tag(modelInfo.speakers[speakerKey]!)
                        }
                    }
                }
            }
            
            TextField("sample_text", text: $hostModel.viewModel.demoText, axis: .vertical)
                .lineLimit(1...10)
                .accessibilityLabel("sample_text: \(hostModel.viewModel.demoText)")
        }
    }
    
    @ViewBuilder
    func notInstalledView() -> some View {
        VStack {
            Button {
                hostModel.install()
            } label: {
                if hostModel.viewModel.showInstallLoadingIndicator {
                    CenteredContent {
                        ProgressView()
                    }
                } else {
                    Text("install_voice_button")
                }
            }
            .disabled(hostModel.viewModel.showInstallLoadingIndicator)
        }
    }
    
    @State var unstallConfirmationShown: Bool = false
    
    @ViewBuilder
    func downloadVoice() -> some View {
        NavigationLink {
            VoicesListView(hostModel: VoicesListHostModel(piper: hostModel.piper, delegate: hostModel))
        } label: {
            Text("download_voice_model")
        }
    }
    
    @ViewBuilder
    func uninstall() -> some View {
        if hostModel.viewModel.installed {
            Button {
                unstallConfirmationShown.toggle()
            } label: {
                Text("uninstall_voice")
                    .foregroundStyle(.red)
            }
            .alert("uninstall_voice", isPresented: $unstallConfirmationShown) {
                Button("uninstall_button", role: .destructive) {
                    hostModel.uninstall()
                }
                Button("cancel", role: .cancel) {
                    unstallConfirmationShown.toggle()
                }
            }
        }
    }
    
    @State var isShowingFileSelector = false
    func selectFromFiles() -> some View {
        Button {
            isShowingFileSelector.toggle()
        } label: {
            Text("update_model_in_app")
        }
        .fileImporter(isPresented: $isShowingFileSelector,
                      allowedContentTypes: [Constants.jsonUTI, Constants.modelUTI],
                      allowsMultipleSelection: true,
                      onCompletion: { results in
            
            switch results {
            case .success(let fileURLs):
                hostModel.selected(files: fileURLs)
            case .failure(let error):
                Log.error("Failed to import model files: \(error)")
            }
        })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let modelInfo = hostModel.viewModel.modelInfo {
                    ModelInfoView(info: modelInfo)
                }
                if hostModel.viewModel.installed {
                    playSampleView()
                }
                Section {
                    downloadVoice()
                    selectFromFiles()
                    if !hostModel.viewModel.installed {
                        notInstalledView()
                    } else {
                        uninstall()
                    }
                }
            }
            .navigationTitle("piper_app_name")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    helpButtonView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    aboutButtonView()
                }
            }
        }
        .sheet(isPresented: $showAboutModalView) {
            AboutAppView(hostModel: AboutAppHostModel(piper: self.hostModel.piper),
                         isPresented: $showAboutModalView)
        }
        .sheet(isPresented: $hostModel.viewModel.showHelp) {
            HelpView(isPresented: $hostModel.viewModel.showHelp)
        }
    }
}

#Preview {
    MainView(hostModel: MainHostModel(piper: PiperManager()))
}
