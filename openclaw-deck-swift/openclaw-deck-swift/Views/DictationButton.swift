// DictationButton.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang.
// Copyright © 2026 OpenClaw. All rights reserved.

import AVFoundation
import SwiftUI

#if os(iOS) || os(visionOS)
    import UIKit
#endif

/// 语音输入按钮 - 点击后开始听写，不弹出键盘
struct DictationButton: View {
    @Binding var text: String
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @State private var errorMessage: String?
    @State private var showingPermissionAlert = false

    var body: some View {
        Button {
            if speechRecognizer.isListening {
                speechRecognizer.stopListening()
            } else {
                // Check availability first
                guard speechRecognizer.isAvailable else {
                    errorMessage = "Speech recognizer is not available on this device"
                    return
                }
                Task {
                    do {
                        try await speechRecognizer.startListening { newText in
                            text = newText
                        }
                        errorMessage = nil
                    } catch let error as SpeechRecognizer.RecognizerError {
                        errorMessage = error.message
                        #if os(iOS) || os(visionOS)
                            if error == .notPermittedToRecord {
                                showingPermissionAlert = true
                            }
                        #endif
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } label: {
            Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                .font(.title3)
                .foregroundStyle(speechRecognizer.isListening ? .red : .accentColor)
        }
        .buttonStyle(.glass)
        .frame(width: 36, height: 36)
        .contentShape(Rectangle())
        #if os(iOS) || os(visionOS)
            .alert("microphone_permission_required".localized, isPresented: $showingPermissionAlert) {
                Button("cancel".localized, role: .cancel) {}
                Button("open_settings".localized) {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("please_enable_microphone_permission_in_settings_to_use_voice_input".localized)
            }
        #endif
    }
}

#Preview {
    struct DictationButtonPreview: View {
        @State private var text = ""
        @StateObject private var speechRecognizer = SpeechRecognizer()

        var body: some View {
            VStack(spacing: 20) {
                Text("dictation_button_preview".localized)
                    .font(.headline)

                HStack {
                    DictationButton(text: $text, speechRecognizer: speechRecognizer)
                        .frame(width: 36, height: 36)

                    TextField("text".localized, text: $text)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()

                Text(String(format: "dictated_text_format".localized, text))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    return DictationButtonPreview()
}
