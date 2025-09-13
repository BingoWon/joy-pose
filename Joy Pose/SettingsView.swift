//
//  SettingsView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(PoseAppModel.self) private var appModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    // Tracking Accuracy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tracking Accuracy")
                            .font(.headline)
                        
                        Picker("Accuracy", selection: .constant(appModel.poseSettings.trackingAccuracy)) {
                            ForEach(PoseSettings.TrackingAccuracy.allCases, id: \.self) { accuracy in
                                Text(accuracy.displayName).tag(accuracy)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Session Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Session Duration")
                            .font(.headline)
                        
                        Picker("Duration", selection: .constant(appModel.poseSettings.preferredSessionDuration)) {
                            ForEach(PoseSettings.SessionDuration.allCases, id: \.self) { duration in
                                Text(duration.displayName).tag(duration)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Toggles
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable Notifications", isOn: .constant(appModel.poseSettings.enableNotifications))
                        Toggle("Auto Save Sessions", isOn: .constant(appModel.poseSettings.autoSaveEnabled))
                    }
                    
                    Spacer()
                    
                    // Reset Button
                    Button("Reset to Defaults") {
                        appModel.poseSettings.resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("JoyPose Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    SettingsView()
        .environment(PoseAppModel())
}
