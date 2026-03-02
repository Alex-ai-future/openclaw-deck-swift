// SpeechRecognizer.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang.
// Copyright © 2026 OpenClaw. All rights reserved.

import AVFoundation
import Combine
import Foundation
import os
import Speech

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

private let logger = Logger(subsystem: "com.openclaw.deck", category: "Speech")

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
                "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize:
                "Not authorized to recognize speech"
            case .notPermittedToRecord:
                "Not permitted to record audio"
            case .recognizerIsUnavailable:
                "Recognizer is unavailable"
            }
        }
    }

    @Published var isListening = false
    @Published var transcript = ""
    @Published var isAvailable: Bool = false
    @Published var isStopping: Bool = false

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?

    init() {
        // 使用中文普通话识别器
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        isAvailable = recognizer?.isAvailable ?? false

        // 测试环境跳过权限检查，避免弹窗
        #if !TESTING
            // Speech recognizer initialized
            checkPermissions()
        #endif
    }

    /// 检查语音识别权限
    private func checkPermissions() {
        // 🧪 跳过权限检查（测试模式）
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return }

        SFSpeechRecognizer.requestAuthorization { authStatus in
            Task { @MainActor in
                switch authStatus {
                case .authorized:
                    // Speech recognition authorized
                    break
                case .denied, .restricted, .notDetermined:
                    logger.error("Speech recognition not authorized: \(authStatus.rawValue)")
                @unknown default:
                    break
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
                    logger.error("Microphone permission denied (iOS 17+)")
                    throw RecognizerError.notPermittedToRecord
                }
            } else {
                // Use legacy AVAudioSession API on iOS 16 and below
                let status = AVAudioSession.sharedInstance().recordPermission

                switch status {
                case .granted:
                    return
                case .denied:
                    logger.error("Microphone permission denied")
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
                        logger.error("Microphone permission denied (request)")
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
                logger.error("Microphone permission denied (macOS)")
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
                await operation()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            let result = await group.next()
            group.cancelAll()
            return result!!
        }
    }

    /// 开始听写
    @MainActor
    func startListening(onTextChange: @escaping (String) -> Void) async throws {
        // startListening called

        // 重置状态，确保每次听写都是新的开始
        transcript = ""
        isStopping = false

        // Check if recognizer is available first
        guard let recognizer else {
            logger.error("Recognizer is nil")
            throw RecognizerError.nilRecognizer
        }

        guard recognizer.isAvailable else {
            logger.error("Recognizer is not available")
            throw RecognizerError.recognizerIsUnavailable
        }

        do {
            // Check microphone permission first
            try await checkMicrophonePermission()
            // Permission granted

            let (audioEngine, request) = try Self.prepareEngine()
            self.audioEngine = audioEngine
            self.request = request

            task = recognizer.recognitionTask(with: request) { result, error in
                Task { @MainActor in
                    if let result, !self.isStopping {
                        // 只在非停止状态下更新 transcript，防止 cancel 后回调污染输入框
                        self.transcript = result.bestTranscription.formattedString
                        onTextChange(self.transcript)
                    }

                    if error != nil || result?.isFinal == true {
                        self.stopListening()
                    }
                }
            }

            isListening = true
            // Listening started
        } catch {
            logger.error("startListening error: \(error.localizedDescription)")
            isListening = false
            throw error
        }
    }

    /// 停止听写
    @MainActor
    func stopListening() {
        isStopping = true // 先设置标志，防止 cancel 后的回调污染输入框
        isListening = false

        task?.cancel()

        if let audioEngine {
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
