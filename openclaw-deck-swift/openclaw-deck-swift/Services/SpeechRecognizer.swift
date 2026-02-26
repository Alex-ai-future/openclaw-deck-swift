// SpeechRecognizer.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang.
// Copyright © 2026 OpenClaw. All rights reserved.

import AVFoundation
import Combine
import Foundation
import Speech

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// 语音识别服务
class SpeechRecognizer: ObservableObject {
  enum RecognizerError: Error {
    case nilRecognizer
    case notAuthorizedToRecognize
    case notPermittedToRecord
    case recognizerIsUnavailable

    var message: String {
      switch self {
      case .nilRecognizer:
        return "Can't initialize speech recognizer"
      case .notAuthorizedToRecognize:
        return "Not authorized to recognize speech"
      case .notPermittedToRecord:
        return "Not permitted to record audio"
      case .recognizerIsUnavailable:
        return "Recognizer is unavailable"
      }
    }
  }

  @Published var isListening = false
  @Published var transcript = ""
  @Published var isAvailable: Bool = false

  private var audioEngine: AVAudioEngine?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var recognizer: SFSpeechRecognizer?

  init() {
    recognizer = SFSpeechRecognizer()
    isAvailable = recognizer?.isAvailable ?? false
    print("[SpeechRecognizer] Initialized, isAvailable: \(isAvailable)")
    checkPermissions()
  }

  /// 检查语音识别权限
  private func checkPermissions() {
    SFSpeechRecognizer.requestAuthorization { authStatus in
      Task { @MainActor in
        switch authStatus {
        case .authorized:
          print("Speech recognition authorized")
        case .denied, .restricted, .notDetermined:
          print("Speech recognition not authorized: \(authStatus)")
        @unknown default:
          print("Unknown authorization status")
        }
      }
    }
  }

  /// 检查麦克风权限
  private func checkMicrophonePermission() async throws {
    #if os(iOS)
      if #available(iOS 17.0, *) {
        // Use new AVAudioApplication API on iOS 17+
        let granted = await withTimeout(timeout: 10) {
          await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
              continuation.resume(returning: granted)
            }
          }
        }
        if !(granted ?? false) {
          print("[SpeechRecognizer] Microphone permission denied (iOS 17+)")
          throw RecognizerError.notPermittedToRecord
        }
      } else {
        // Use legacy AVAudioSession API on iOS 16 and below
        let status = AVAudioSession.sharedInstance().recordPermission

        switch status {
        case .granted:
          return
        case .denied:
          print("[SpeechRecognizer] Microphone permission denied")
          throw RecognizerError.notPermittedToRecord
        case .undetermined:
          let granted = await withTimeout(timeout: 10) {
            await withCheckedContinuation { continuation in
              AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
              }
            }
          }
          if !(granted ?? false) {
            print("[SpeechRecognizer] Microphone permission denied (request)")
            throw RecognizerError.notPermittedToRecord
          }
        @unknown default:
          throw RecognizerError.notPermittedToRecord
        }
      }
    #elseif os(macOS)
      // macOS uses AVAudioApplication API
      let granted = await withTimeout(timeout: 10) {
        await withCheckedContinuation { continuation in
          AVAudioApplication.requestRecordPermission { granted in
            continuation.resume(returning: granted)
          }
        }
      }
      if !(granted ?? false) {
        print("[SpeechRecognizer] Microphone permission denied (macOS)")
        throw RecognizerError.notPermittedToRecord
      }
    #endif
  }

  /// Helper to add timeout to async operations
  private func withTimeout<T>(timeout: TimeInterval, operation: @escaping () async -> T?) async
    -> T?
  {
    await withTaskGroup(of: T?.self) { group in
      group.addTask {
        return await operation()
      }
      group.addTask {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        return nil
      }
      let result = await group.next()
      group.cancelAll()
      return result as! T?
    }
  }

  /// 开始听写
  @MainActor
  func startListening(onTextChange: @escaping (String) -> Void) async throws {
    print("[SpeechRecognizer] startListening called")

    // Check if recognizer is available first
    guard let recognizer = recognizer else {
      print("[SpeechRecognizer] recognizer is nil")
      throw RecognizerError.nilRecognizer
    }

    guard recognizer.isAvailable else {
      print("[SpeechRecognizer] recognizer is not available")
      throw RecognizerError.recognizerIsUnavailable
    }

    do {
      // Check microphone permission first
      print("[SpeechRecognizer] Checking microphone permission...")
      try await checkMicrophonePermission()
      print("[SpeechRecognizer] Microphone permission granted")

      let (audioEngine, request) = try Self.prepareEngine()
      self.audioEngine = audioEngine
      self.request = request

      task = recognizer.recognitionTask(with: request) { result, error in
        Task { @MainActor in
          if let result = result {
            self.transcript = result.bestTranscription.formattedString
            onTextChange(self.transcript)
          }

          if error != nil || result?.isFinal == true {
            print(
              "[SpeechRecognizer] Recognition finished: error=\(error?.localizedDescription ?? "nil"), isFinal=\(result?.isFinal ?? false)"
            )
            self.stopListening()
          }
        }
      }

      self.isListening = true
      print("[SpeechRecognizer] Listening started")
    } catch {
      print("[SpeechRecognizer] startListening error: \(error)")
      self.isListening = false
      throw error
    }
  }

  /// 停止听写
  @MainActor
  func stopListening() {
    self.isListening = false

    task?.cancel()

    if let audioEngine = audioEngine {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }

    request = nil
    task = nil
  }

  /// 准备音频引擎
  private static func prepareEngine() throws -> (
    AVAudioEngine, SFSpeechAudioBufferRecognitionRequest
  ) {
    let audioEngine = AVAudioEngine()

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true

    #if os(iOS)
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    #endif

    let inputNode = audioEngine.inputNode

    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
      request.append(buffer)
    }

    audioEngine.prepare()
    try audioEngine.start()

    return (audioEngine, request)
  }
}
