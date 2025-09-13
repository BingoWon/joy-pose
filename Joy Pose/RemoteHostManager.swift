//
//  RemoteHostManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

struct HostConfiguration: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let hostname: String
    let port: Int
    let username: String
    let password: String
    
    static func == (lhs: HostConfiguration, rhs: HostConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
}

@Observable
class RemoteHostManager {
    static let shared = RemoteHostManager()

    var connectionState: ConnectionState = .disconnected
    var currentHost: HostConfiguration?

    private init() {}

    func connect(to host: HostConfiguration, password: String? = nil) async {
        await MainActor.run {
            connectionState = .connecting
            currentHost = host
        }

        // Simulate connection attempt
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        await MainActor.run {
            connectionState = .connected
            print("🎯 Connected to \(host.hostname)")
        }
    }

    func disconnect() async {
        await MainActor.run {
            connectionState = .disconnected
            currentHost = nil
            print("🎯 Disconnected from remote host")
        }
    }
}
