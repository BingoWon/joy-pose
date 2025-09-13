//
//  PoseSettings.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

@Observable
final class PoseSettings {
    
    // MARK: - Settings Keys
    
    private enum Keys {
        static let trackingAccuracy = "pose_tracking_accuracy"
        static let sessionDuration = "pose_session_duration"
        static let enableNotifications = "pose_enable_notifications"
        static let autoSaveEnabled = "pose_auto_save_enabled"
    }
    
    // MARK: - Properties
    
    var trackingAccuracy: TrackingAccuracy {
        didSet { UserDefaults.standard.set(trackingAccuracy.rawValue, forKey: Keys.trackingAccuracy) }
    }
    
    var preferredSessionDuration: SessionDuration {
        didSet { UserDefaults.standard.set(preferredSessionDuration.rawValue, forKey: Keys.sessionDuration) }
    }
    
    var enableNotifications: Bool {
        didSet { UserDefaults.standard.set(enableNotifications, forKey: Keys.enableNotifications) }
    }
    
    var autoSaveEnabled: Bool {
        didSet { UserDefaults.standard.set(autoSaveEnabled, forKey: Keys.autoSaveEnabled) }
    }
    
    // MARK: - Enums
    
    enum TrackingAccuracy: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case ultra = "ultra"
        
        var displayName: String {
            switch self {
            case .low: return "Low (Battery Saving)"
            case .medium: return "Medium (Balanced)"
            case .high: return "High (Recommended)"
            case .ultra: return "Ultra (Maximum Precision)"
            }
        }
    }
    
    enum SessionDuration: Int, CaseIterable {
        case short = 5
        case medium = 15
        case long = 30
        case extended = 60
        
        var displayName: String {
            switch self {
            case .short: return "5 minutes"
            case .medium: return "15 minutes"
            case .long: return "30 minutes"
            case .extended: return "60 minutes"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved settings or use defaults
        self.trackingAccuracy = TrackingAccuracy(
            rawValue: UserDefaults.standard.string(forKey: Keys.trackingAccuracy) ?? ""
        ) ?? .high
        
        self.preferredSessionDuration = SessionDuration(
            rawValue: UserDefaults.standard.integer(forKey: Keys.sessionDuration)
        ) ?? .medium
        
        self.enableNotifications = UserDefaults.standard.object(forKey: Keys.enableNotifications) as? Bool ?? true
        self.autoSaveEnabled = UserDefaults.standard.object(forKey: Keys.autoSaveEnabled) as? Bool ?? true
        
        print("⚙️ PoseSettings initialized with accuracy: \(trackingAccuracy.displayName)")
    }
    
    // MARK: - Convenience Methods
    
    func resetToDefaults() {
        trackingAccuracy = .high
        preferredSessionDuration = .medium
        enableNotifications = true
        autoSaveEnabled = true
        
        print("⚙️ Settings reset to defaults")
    }
    
    func exportSettings() -> [String: Any] {
        return [
            "trackingAccuracy": trackingAccuracy.rawValue,
            "sessionDuration": preferredSessionDuration.rawValue,
            "enableNotifications": enableNotifications,
            "autoSaveEnabled": autoSaveEnabled
        ]
    }
    
    func importSettings(from data: [String: Any]) {
        if let accuracy = data["trackingAccuracy"] as? String,
           let trackingAccuracy = TrackingAccuracy(rawValue: accuracy) {
            self.trackingAccuracy = trackingAccuracy
        }
        
        if let duration = data["sessionDuration"] as? Int,
           let sessionDuration = SessionDuration(rawValue: duration) {
            self.preferredSessionDuration = sessionDuration
        }
        
        if let notifications = data["enableNotifications"] as? Bool {
            self.enableNotifications = notifications
        }
        
        if let autoSave = data["autoSaveEnabled"] as? Bool {
            self.autoSaveEnabled = autoSave
        }
        
        print("⚙️ Settings imported successfully")
    }
}

