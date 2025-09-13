//
//  FileTreeSidebar.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

/// VSCode-style file tree sidebar component
struct FileTreeSidebar: View {
    @Bindable var fileTreeManager: FileTreeManager
    @Bindable var hostManager: RemoteHostManager
    @Binding var selectedFile: RemoteFile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    fileTreeContent
                }
            }
        }
        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
        .background(.regularMaterial)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("EXPLORER")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            connectionStatusIndicator
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
    
    private var connectionStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(hostManager.connectionState == .connected ? .green : .red)
                .frame(width: 6, height: 6)
            
            Text(hostManager.connectionState.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - File Tree Content
    
    @ViewBuilder
    private var fileTreeContent: some View {
        // Start from root directory
        rootDirectoryView
    }

    private var rootDirectoryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Root directory entry
            FileTreeRowView(
                file: RemoteFile(
                    name: "/",
                    path: "/",
                    isDirectory: true,
                    size: 0,
                    modificationDate: Date()
                ),
                level: 0,
                fileTreeManager: fileTreeManager,
                selectedFile: $selectedFile,
                onDirectoryToggle: { path in
                    Task.detached {
                        await loadDirectory(path)
                    }
                }
            )
        }
        .task {
            await initializeFileTree()
        }
    }
    
    // MARK: - Helper Methods

    private func initializeFileTree() async {
        // Expand root directory first
        await loadDirectory("/")

        // Auto-expand path to current directory
        await expandPathToCurrentDirectory()
    }

    private func expandPathToCurrentDirectory() async {
        let currentPath = hostManager.currentDirectory
        let pathComponents = currentPath.components(separatedBy: "/").filter { !$0.isEmpty }

        var buildPath = ""
        for component in pathComponents {
            buildPath += "/" + component

            // Expand this directory
            await MainActor.run {
                fileTreeManager.expandedDirectories.insert(buildPath)
            }

            // Load directory contents
            await loadDirectory(buildPath)
        }

        // Ensure root is expanded
        await MainActor.run {
            fileTreeManager.expandedDirectories.insert("/")
        }
    }

    private func loadDirectory(_ path: String) async {
        // Perform network operation on background thread
        let files = await hostManager.getDirectoryContents(path)

        // Update cache on main thread to ensure UI consistency
        await MainActor.run {
            fileTreeManager.cacheFiles(files, for: path)
        }
    }
}

// MARK: - FileTreeRowView

struct FileTreeRowView: View {
    let file: RemoteFile
    let level: Int
    @Bindable var fileTreeManager: FileTreeManager
    @Binding var selectedFile: RemoteFile?
    let onDirectoryToggle: (String) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File/Directory row
            Button {
                if file.isDirectory {
                    // First check if we need to load directory contents
                    let wasExpanded = fileTreeManager.isExpanded(file.path)

                    // Toggle the directory state
                    fileTreeManager.toggleDirectory(file.path)

                    // If directory is now expanded and wasn't before, load contents
                    if !wasExpanded && fileTreeManager.isExpanded(file.path) {
                        // Use Task.detached to run network operations on background thread
                        Task.detached {
                            await onDirectoryToggle(file.path)
                        }
                    }
                } else {
                    selectedFile = file
                }
            } label: {
                HStack(spacing: 4) {
                    // Indentation
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: CGFloat(level * 16))

                    // Expand/collapse icon for directories
                    if file.isDirectory {
                        Image(systemName: fileTreeManager.isExpanded(file.path) ?
                              "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 14)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 14)
                    }

                    // File icon
                    Image(systemName: fileIcon(for: file))
                        .font(.body)
                        .foregroundStyle(file.isDirectory ? .blue : .primary)
                        .frame(width: 20)

                    // File name
                    Text(file.name)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .frame(height: 45)  // Fixed height of 45px
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                selectedFile?.id == file.id ?
                Color.accentColor.opacity(0.3) : Color.clear
            )

            // Expanded directory contents
            if file.isDirectory && fileTreeManager.isExpanded(file.path) {
                if let subFiles = fileTreeManager.getCachedFiles(for: file.path) {
                    let filteredSubFiles = fileTreeManager.filteredAndSortedFiles(subFiles)
                    ForEach(filteredSubFiles, id: \.id) { subFile in
                        FileTreeRowView(
                            file: subFile,
                            level: level + 1,
                            fileTreeManager: fileTreeManager,
                            selectedFile: $selectedFile,
                            onDirectoryToggle: onDirectoryToggle
                        )
                    }
                }
            }
        }
    }

    private func fileIcon(for file: RemoteFile) -> String {
        if file.isDirectory {
            return fileTreeManager.isExpanded(file.path) ? "folder.fill" : "folder"
        }

        let ext = file.name.lowercased()
        if ext.hasSuffix(".swift") { return "swift" }
        if ext.hasSuffix(".py") { return "doc.text" }
        if ext.hasSuffix(".js") || ext.hasSuffix(".ts") { return "doc.text" }
        if ext.hasSuffix(".html") || ext.hasSuffix(".css") { return "doc.text" }
        if ext.hasSuffix(".json") || ext.hasSuffix(".xml") { return "doc.text" }
        if ext.hasSuffix(".md") || ext.hasSuffix(".txt") { return "doc.plaintext" }
        if ext.hasSuffix(".jpg") || ext.hasSuffix(".png") || ext.hasSuffix(".gif") { return "photo" }
        if ext.hasSuffix(".pdf") { return "doc.richtext" }
        if ext.hasSuffix(".zip") || ext.hasSuffix(".tar") || ext.hasSuffix(".gz") { return "archivebox" }

        return "doc.text"
    }
}
