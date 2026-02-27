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
      // macOS: 使用系统消息音
      NSSound.beep()
    #else
      // iOS: 使用系统短信提示音
      AudioServicesPlaySystemSound(1005)
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
