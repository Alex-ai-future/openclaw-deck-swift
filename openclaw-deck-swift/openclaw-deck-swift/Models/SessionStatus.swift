// SessionStatus.swift
// OpenClaw Deck Swift
//
// Session status enumeration

import Foundation

/// Session 状态
enum SessionStatus: Hashable {
    case idle
    case thinking
    case speaking
    case error(String)
}
