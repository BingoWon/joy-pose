//
//  AppModel.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

@MainActor @Observable
class AppModel {
    // Placeholder app model for remote development environment
    var isConnected = false
    var connectionStatus = "Not Connected"
    
    init() {
        print("🎯 JoyPose AppModel initialized")
    }
}