//
//  JoyPoseLogger.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import OSLog

/// Simple logging system for JoyPose application
class JoyPoseLogger {
    static let shared = JoyPoseLogger()
    
    enum Category: String, CaseIterable {
        case general = "General"
        case terminal = "Terminal"
        case ui = "UI"
        case connection = "Connection"
        case fileManager = "FileManager"
        case ai = "AI"
    }
    
    private let subsystem = "Bin.Joy-Pose"
    private var loggers: [Category: Logger] = [:]
    
    private init() {
        // Initialize loggers for each category
        for category in Category.allCases {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    func info(_ message: String, category: Category = .general) {
        loggers[category]?.info("\(message, privacy: .public)")
    }
    
    func debug(_ message: String, category: Category = .general) {
        loggers[category]?.debug("\(message, privacy: .public)")
    }
    
    func warning(_ message: String, category: Category = .general) {
        loggers[category]?.warning("\(message, privacy: .public)")
    }
    
    func error(_ message: String, category: Category = .general) {
        loggers[category]?.error("\(message, privacy: .public)")
    }
}

/// Global logger instance for convenience
let logger = JoyPoseLogger.shared

