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
            "Idle"
        case .initializing:
            "Initializing..."
        case .loadingSessions:
            "Loading sessions..."
        case .connectingToGateway:
            "Connecting to gateway..."
        case .syncingFromCloud:
            "Syncing from cloud..."
        case .ready:
            "Ready"
        }
    }
}
