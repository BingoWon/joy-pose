//
//  PoseWindowManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

@Observable
class PoseWindowManager {
    static let shared = PoseWindowManager()

    // Window visibility state
    var isSettingsOpen = false
    var isHistoryOpen = false
    
    // Window availability state
    var shouldShowSettings = false
    var shouldShowHistory = false

    private var hasHandledAppLaunch = false

    private init() {}

    func handleAppLaunch() {
        guard !hasHandledAppLaunch else { return }
        hasHandledAppLaunch = true

        // Initialize window availability
        shouldShowSettings = false
        shouldShowHistory = false

        print("🪟 PoseWindowManager initialized - Multi-window management ready")
    }

    // MARK: - Settings Window Management
    
    func enableSettings() {
        shouldShowSettings = true
        isSettingsOpen = true
        print("⚙️ Settings window enabled")
    }

    func disableSettings() {
        shouldShowSettings = false
        isSettingsOpen = false
        print("⚙️ Settings window disabled")
    }

    // MARK: - History Window Management
    
    func enableHistory() {
        shouldShowHistory = true
        isHistoryOpen = true
        print("📊 History window enabled")
    }

    func disableHistory() {
        shouldShowHistory = false
        isHistoryOpen = false
        print("📊 History window disabled")
    }

    // MARK: - Window State Management
    
    func closeAllSecondaryWindows() {
        disableSettings()
        disableHistory()
        print("🪟 All secondary windows closed")
    }
    
    func getOpenWindowsCount() -> Int {
        var count = 1 // Main window is always open
        if isSettingsOpen { count += 1 }
        if isHistoryOpen { count += 1 }
        return count
    }
}
