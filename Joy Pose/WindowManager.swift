//
//  WindowManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

@Observable
class WindowManager {
    static let shared = WindowManager()

    var isRemoteTerminalOpen = false
    var isRemoteFileManagerOpen = false
    var isAIAgentsOpen = false

    var shouldShowRemoteTerminal = false
    var shouldShowRemoteFileManager = false
    var shouldShowAIAgents = false

    private var hasHandledAppLaunch = false

    private init() {}

    func handleAppLaunch() {
        guard !hasHandledAppLaunch else { return }
        hasHandledAppLaunch = true

        shouldShowRemoteTerminal = false
        shouldShowRemoteFileManager = false
        shouldShowAIAgents = false

        print("🎯 JoyPose app launch handled")
    }

    @MainActor
    var canOpenAIAgents: Bool {
        RooCodeConnectionManager.shared.isConnected
    }

    func enableAIAgents() {
        shouldShowAIAgents = true
        isAIAgentsOpen = true
    }

    func disableAIAgents() {
        shouldShowAIAgents = false
        isAIAgentsOpen = false
    }
    
    func enableRemoteTerminal() {
        guard RemoteHostManager.shared.connectionState == .connected else { return }
        shouldShowRemoteTerminal = true
        isRemoteTerminalOpen = true
    }

    func disableRemoteTerminal() {
        shouldShowRemoteTerminal = false
        isRemoteTerminalOpen = false
    }

    func enableRemoteFileManager() {
        guard RemoteHostManager.shared.connectionState == .connected else { return }
        shouldShowRemoteFileManager = true
        isRemoteFileManagerOpen = true
    }

    func disableRemoteFileManager() {
        shouldShowRemoteFileManager = false
        isRemoteFileManagerOpen = false
    }

    func handleConnectionStateChange(_ state: ConnectionState) {
        if state != .connected {
            disableRemoteTerminal()
            disableRemoteFileManager()
        }
    }
}
