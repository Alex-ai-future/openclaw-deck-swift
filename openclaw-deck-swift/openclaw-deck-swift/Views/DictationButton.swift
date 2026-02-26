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
  @StateObject private var speechRecognizer = SpeechRecognizer()
  @State private var errorMessage: String?
  @State private var showingPermissionAlert = false

  var body: some View {
    Button {
      print(
        "[DictationButton] Tapped, isListening: \(speechRecognizer.isListening), isAvailable: \(speechRecognizer.isAvailable)"
      )
      if speechRecognizer.isListening {
        speechRecognizer.stopListening()
      } else {
        // Check availability first
        guard speechRecognizer.isAvailable else {
          errorMessage = "Speech recognizer is not available on this device"
          print("[DictationButton] Speech recognizer not available")
          return
        }
        Task {
          do {
            print("[DictationButton] Starting listening...")
            try await speechRecognizer.startListening { newText in
              text = newText
            }
            errorMessage = nil
            print("[DictationButton] Listening succeeded")
          } catch let error as SpeechRecognizer.RecognizerError {
            errorMessage = error.message
            print("[DictationButton] RecognizerError: \(error.message)")
            #if os(iOS) || os(visionOS)
              if error == .notPermittedToRecord {
                showingPermissionAlert = true
              }
            #endif
          } catch {
            errorMessage = error.localizedDescription
            print("[DictationButton] Error: \(error.localizedDescription)")
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
      .alert("麦克风权限 needed", isPresented: $showingPermissionAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Open Settings") {
          if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
          }
        }
      } message: {
        Text("请在设置中启用麦克风权限以使用语音输入功能")
      }
    #endif
  }
}

#Preview {
  struct DictationButtonPreview: View {
    @State private var text = ""

    var body: some View {
      VStack(spacing: 20) {
        Text("Dictation Button Preview")
          .font(.headline)

        HStack {
          DictationButton(text: $text)
            .frame(width: 36, height: 36)

          TextField("Text", text: $text)
            .textFieldStyle(.roundedBorder)
        }
        .padding()

        Text("Dictated: \(text)")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  return DictationButtonPreview()
}
