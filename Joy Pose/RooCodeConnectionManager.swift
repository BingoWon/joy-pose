//
//  RooCodeConnectionManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation

enum RooCodeConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
    
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .failed(let error): return "Failed: \(error)"
        }
    }
}

@Observable
class RooCodeConnectionManager {
    static let shared = RooCodeConnectionManager()

    var connectionState: RooCodeConnectionState = .disconnected
    var isScanning = false

    private init() {}

    var isConnected: Bool {
        connectionState == .connected
    }
}

