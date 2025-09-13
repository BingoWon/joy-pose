//
//  Joy_PoseApp.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

@main
struct Joy_PoseApp: App {
    @State private var appModel = AppModel()
    @State private var windowManager = WindowManager.shared

    init() {
        print("🎯 JoyPose application launched - Pure 2D visionOS remote development environment")
    }

    var body: some Scene {
        // Main control window - always displayed on app launch
        WindowGroup("JoyPose Control", id: "main-control") {
            MainControlView()
                .environment(appModel)
                .onAppear {
                    windowManager.handleAppLaunch()
                }
        }
        .defaultSize(width: 800, height: 700)
        .windowResizability(.contentSize)

        // Remote terminal window - only available when connected
        WindowGroup("Remote Terminal", id: "remote-terminal") {
            if windowManager.shouldShowRemoteTerminal {
                RemoteTerminalView()
            } else {
                EmptyView()
            }
        }
        .defaultSize(width: 1000, height: 1000)

        // Remote file manager window - only available when connected
        WindowGroup("Remote File Manager", id: "remote-file-manager") {
            if windowManager.shouldShowRemoteFileManager {
                RemoteFileManagerView()
            } else {
                EmptyView()
            }
        }
        .defaultSize(width: 1200, height: 800)

        // AI Agents window - only available when connected to Roo Code
        WindowGroup("AI Agents", id: "ai-agents") {
            if windowManager.shouldShowAIAgents {
                AIAgentsView()
                    .environment(appModel)
            } else {
                EmptyView()
            }
        }
        .defaultSize(width: 1000, height: 800)
    }
}
