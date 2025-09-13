//
//  FileTreeManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI
import Foundation

/// Optimized file tree management with caching and performance optimization
@MainActor @Observable
final class FileTreeManager {
    
    // MARK: - State Management
    
    var expandedDirectories: Set<String> = ["/"]
    var fileTreeCache: [String: [RemoteFile]] = [:]
    var searchText = ""
    var showHiddenFiles = false
    var sortOrder: SortOrder = .name
    var selectedFiles: Set<RemoteFile> = []
    
    // MARK: - Cache Management
    
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    private var cacheTimestamps: [String: Date] = [:]
    
    enum SortOrder: CaseIterable {
        case name, size, date
        
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .size: return "Size" 
            case .date: return "Date"
            }
        }
    }
    
    // MARK: - Public Methods
    
    func toggleDirectory(_ path: String) {
        if expandedDirectories.contains(path) {
            expandedDirectories.remove(path)
        } else {
            expandedDirectories.insert(path)
        }
    }
    
    func isExpanded(_ path: String) -> Bool {
        expandedDirectories.contains(path)
    }
    
    func cacheFiles(_ files: [RemoteFile], for directory: String) {
        fileTreeCache[directory] = files
        cacheTimestamps[directory] = Date()
    }
    
    func getCachedFiles(for directory: String) -> [RemoteFile]? {
        guard let timestamp = cacheTimestamps[directory],
              Date().timeIntervalSince(timestamp) < cacheExpirationTime else {
            // Cache expired, remove it
            fileTreeCache.removeValue(forKey: directory)
            cacheTimestamps.removeValue(forKey: directory)
            return nil
        }
        return fileTreeCache[directory]
    }
    
    func filteredAndSortedFiles(_ files: [RemoteFile]) -> [RemoteFile] {
        var filtered = files
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { file in
                file.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply hidden files filter
        if !showHiddenFiles {
            filtered = filtered.filter { !$0.name.hasPrefix(".") }
        }
        
        // Apply sorting
        return filtered.sorted { lhs, rhs in
            // Directories first
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            
            switch sortOrder {
            case .name:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .size:
                return lhs.size < rhs.size
            case .date:
                return lhs.modificationDate > rhs.modificationDate
            }
        }
    }
    
    func clearCache() {
        fileTreeCache.removeAll()
        cacheTimestamps.removeAll()
    }

    // MARK: - Path Expansion

    func expandPathToDirectory(_ targetPath: String) {
        let pathComponents = targetPath.components(separatedBy: "/").filter { !$0.isEmpty }

        var buildPath = ""
        for component in pathComponents {
            buildPath += "/" + component
            expandedDirectories.insert(buildPath)
        }

        // Ensure root is expanded
        expandedDirectories.insert("/")
    }
}

