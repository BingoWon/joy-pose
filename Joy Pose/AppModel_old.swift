//
//  PoseAppModel.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

/// Maintains app-wide state for JoyPose - Pure 2D visionOS application
@MainActor
@Observable
class PoseAppModel {
    
    // MARK: - Pose Tracking State
    private(set) var poseTrackingState: PoseTrackingState = .idle
    private(set) var currentSession: PoseSession?
    
    // MARK: - Settings Management
    let poseSettings = PoseSettings()
    
    // MARK: - History Management  
    let poseHistory = PoseHistoryModel()
    
    // MARK: - Performance Metrics
    private(set) var sessionMetrics = SessionMetrics()
    
    enum PoseTrackingState: Equatable {
        case idle
        case calibrating
        case tracking
        case paused
        case completed
        case error(String)
    }
    
    struct PoseSession {
        let id: String
        let startTime: Date
        var endTime: Date?
        var duration: TimeInterval { 
            (endTime ?? Date()).timeIntervalSince(startTime) 
        }
        var poseCount: Int = 0
        var accuracy: Double = 0.0
    }
    
    struct SessionMetrics {
        var totalSessions: Int = 0
        var totalDuration: TimeInterval = 0
        var averageAccuracy: Double = 0.0
        var bestAccuracy: Double = 0.0
        var totalPoses: Int = 0
    }
    
    init() {
        print("🎮 PoseAppModel initialized - Modern state management ready")
        
        // Load saved metrics
        loadSessionMetrics()
        
        // Setup automatic session saving
        setupAutoSave()
    }
    
    // MARK: - Session Management
    
    func startNewSession() {
        let session = PoseSession(
            id: UUID().uuidString,
            startTime: Date()
        )
        currentSession = session
        poseTrackingState = .calibrating
        
        print("🎯 New pose session started: \(session.id)")
    }
    
    func completeCurrentSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        poseHistory.addSession(session)
        updateSessionMetrics(with: session)
        
        currentSession = nil
        poseTrackingState = .completed
        
        print("✅ Session completed: \(session.duration)s, accuracy: \(session.accuracy)")
    }
    
    func pauseSession() {
        guard poseTrackingState == .tracking else { return }
        poseTrackingState = .paused
    }
    
    func resumeSession() {
        guard poseTrackingState == .paused else { return }
        poseTrackingState = .tracking
    }
    
    // MARK: - State Updates
    
    func updateTrackingState(_ state: PoseTrackingState) {
        poseTrackingState = state
    }
    
    func updateSessionAccuracy(_ accuracy: Double) {
        currentSession?.accuracy = accuracy
    }
    
    func incrementPoseCount() {
        currentSession?.poseCount += 1
    }
    
    // MARK: - Metrics Management
    
    private func updateSessionMetrics(with session: PoseSession) {
        sessionMetrics.totalSessions += 1
        sessionMetrics.totalDuration += session.duration
        sessionMetrics.totalPoses += session.poseCount
        
        if session.accuracy > sessionMetrics.bestAccuracy {
            sessionMetrics.bestAccuracy = session.accuracy
        }
        
        // Calculate average accuracy
        sessionMetrics.averageAccuracy = poseHistory.averageAccuracy
        
        saveSessionMetrics()
    }
    
    private func loadSessionMetrics() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "SessionMetrics") {
            do {
                sessionMetrics = try JSONDecoder().decode(SessionMetrics.self, from: data)
            } catch {
                print("⚠️ Failed to load session metrics: \(error)")
            }
        }
    }
    
    private func saveSessionMetrics() {
        do {
            let data = try JSONEncoder().encode(sessionMetrics)
            UserDefaults.standard.set(data, forKey: "SessionMetrics")
        } catch {
            print("⚠️ Failed to save session metrics: \(error)")
        }
    }
    
    private func setupAutoSave() {
        // Auto-save every 30 seconds during active sessions
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            if self?.poseTrackingState == .tracking {
                self?.saveSessionMetrics()
            }
        }
    }
}

// MARK: - Codable Extensions

extension PoseAppModel.SessionMetrics: Codable {}
extension PoseAppModel.PoseSession: Codable {}
