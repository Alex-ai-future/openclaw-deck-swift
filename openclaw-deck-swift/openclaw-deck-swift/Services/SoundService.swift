// SoundService.swift
// OpenClaw Deck Swift
//
// 跨平台声音服务

import Foundation

#if os(macOS)
  import AppKit
#else
  import UIKit
  import AudioToolbox
#endif

/// 跨平台声音服务
class SoundService {
  static let shared = SoundService()

  /// 播放消息提示音
  func playMessageNotification() {
    #if os(macOS)
      // macOS: 使用更响亮的系统声音
      if let sound = NSSound(named: "Glass") {
        sound.volume = 1.0
        sound.play()
      } else {
        NSSound.beep()
      }
    #else
      // iOS/iPadOS: 连续播放 3 次增强效果
      // 1014 - 多消息提示音（很响亮）
      for i in 0..<3 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
          AudioServicesPlayAlertSound(1014)
        }
      }
    #endif
  }

  /// 播放错误提示音
  func playErrorSound() {
    #if os(macOS)
      NSSound.beep()
    #else
      AudioServicesPlaySystemSound(1001)
    #endif
  }
}
