//
//  PoseHistoryModel.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

@Observable
final class PoseHistoryModel {
    
    // MARK: - Properties
    
    private(set) var sessions: [PoseSession] = []
    private let maxStoredSessions = 100
    
    // MARK: - Computed Properties
    
    var totalSessions: Int {
        sessions.count
    }
    
    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    var averageAccuracy: Double {
        guard !sessions.isEmpty else { return 0.0 }
        let totalAccuracy = sessions.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Double(sessions.count)
    }
    
    var bestSession: PoseSession? {
        sessions.max { $0.accuracy < $1.accuracy }
    }
    
    var recentSessions: [PoseSession] {
        Array(sessions.prefix(10))
    }
    
    // MARK: - Initialization
    
    init() {
        loadSessions()
        print("📊 PoseHistoryModel initialized with \(sessions.count) sessions")
    }
    
    // MARK: - Session Management
    
    func addSession(_ session: PoseSession) {
        sessions.insert(session, at: 0) // Add to beginning for chronological order
        
        // Maintain maximum session limit
        if sessions.count > maxStoredSessions {
            sessions = Array(sessions.prefix(maxStoredSessions))
        }
        
        saveSessions()
        print("📊 Session added: \(session.id), total sessions: \(sessions.count)")
    }
    
    func removeSession(withId id: String) {
        sessions.removeAll { $0.id == id }
        saveSessions()
        print("📊 Session removed: \(id)")
    }
    
    func clearAllSessions() {
        sessions.removeAll()
        saveSessions()
        print("📊 All sessions cleared")
    }
    
    // MARK: - Data Analysis
    
    func getSessionsForDateRange(from startDate: Date, to endDate: Date) -> [PoseSession] {
        return sessions.filter { session in
            session.startTime >= startDate && session.startTime <= endDate
        }
    }
    
    func getAverageAccuracyForLastWeek() -> Double {
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let recentSessions = getSessionsForDateRange(from: oneWeekAgo, to: Date())
        
        guard !recentSessions.isEmpty else { return 0.0 }
        
        let totalAccuracy = recentSessions.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Double(recentSessions.count)
    }
    
    func getProgressTrend() -> ProgressTrend {
        guard sessions.count >= 5 else { return .insufficient }
        
        let recent5 = Array(sessions.prefix(5))
        let older5 = Array(sessions.dropFirst(5).prefix(5))
        
        guard older5.count == 5 else { return .insufficient }
        
        let recentAvg = recent5.reduce(0.0) { $0 + $1.accuracy } / 5.0
        let olderAvg = older5.reduce(0.0) { $0 + $1.accuracy } / 5.0
        
        let improvement = recentAvg - olderAvg
        
        if improvement > 0.05 {
            return .improving
        } else if improvement < -0.05 {
            return .declining
        } else {
            return .stable
        }
    }
    
    // MARK: - Persistence
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "PoseSessions") {
            do {
                sessions = try JSONDecoder().decode([PoseSession].self, from: data)
            } catch {
                print("⚠️ Failed to load pose sessions: \(error)")
                sessions = []
            }
        }
    }
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: "PoseSessions")
        } catch {
            print("⚠️ Failed to save pose sessions: \(error)")
        }
    }
    
    // MARK: - Export/Import
    
    func exportSessionsToJSON() -> Data? {
        do {
            return try JSONEncoder().encode(sessions)
        } catch {
            print("⚠️ Failed to export sessions: \(error)")
            return nil
        }
    }
    
    func importSessionsFromJSON(_ data: Data) -> Bool {
        do {
            let importedSessions = try JSONDecoder().decode([PoseSession].self, from: data)
            
            // Merge with existing sessions, avoiding duplicates
            for session in importedSessions {
                if !sessions.contains(where: { $0.id == session.id }) {
                    sessions.append(session)
                }
            }
            
            // Sort by date (newest first)
            sessions.sort { $0.startTime > $1.startTime }
            
            // Maintain session limit
            if sessions.count > maxStoredSessions {
                sessions = Array(sessions.prefix(maxStoredSessions))
            }
            
            saveSessions()
            print("📊 Imported \(importedSessions.count) sessions")
            return true
        } catch {
            print("⚠️ Failed to import sessions: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Types

extension PoseHistoryModel {
    enum ProgressTrend {
        case improving
        case stable
        case declining
        case insufficient
        
        var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Needs Work"
            case .insufficient: return "Need More Data"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .green
            case .stable: return .blue
            case .declining: return .orange
            case .insufficient: return .gray
            }
        }
    }
}

// MARK: - Type Aliases

typealias PoseSession = PoseAppModel.PoseSession

