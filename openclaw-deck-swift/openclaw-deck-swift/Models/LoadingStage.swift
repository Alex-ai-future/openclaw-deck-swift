// LoadingStage.swift
// OpenClaw Deck Swift
//
// Loading stage enumeration for app initialization

import Foundation

/// App 加载阶段
enum LoadingStage: Comparable, Hashable {
    case idle
    case initializing
    case loadingSessions
    case connectingToGateway
    case syncingFromCloud
    case ready
    
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .initializing:
            return "Initializing..."
        case .loadingSessions:
            return "Loading sessions..."
        case .connectingToGateway:
            return "Connecting to gateway..."
        case .syncingFromCloud:
            return "Syncing from cloud..."
        case .ready:
            return "Ready"
        }
    }
}
