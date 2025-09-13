//
//  HistoryView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct HistoryView: View {
    @Environment(PoseAppModel.self) private var appModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Pose History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(appModel.poseHistory.totalSessions) sessions recorded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Stats Overview
                HStack(spacing: 20) {
                    statCard(
                        title: "Total Sessions",
                        value: "\(appModel.sessionMetrics.totalSessions)",
                        icon: "list.number"
                    )
                    
                    statCard(
                        title: "Best Accuracy",
                        value: "\(Int(appModel.sessionMetrics.bestAccuracy * 100))%",
                        icon: "target"
                    )
                    
                    statCard(
                        title: "Total Time",
                        value: formatDuration(appModel.sessionMetrics.totalDuration),
                        icon: "clock"
                    )
                }
                .padding(.horizontal)
                
                // Recent Sessions List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(appModel.poseHistory.recentSessions, id: \.id) { session in
                                sessionRow(session)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(width: 1000, height: 600)
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func sessionRow(_ session: PoseSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Session \(session.id.prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(session.accuracy * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                
                Text(formatDuration(session.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    HistoryView()
        .environment(PoseAppModel())
}
