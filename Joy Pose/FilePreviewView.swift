//
//  FilePreviewView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct FilePreviewView: View {
    let file: RemoteFile?
    @State private var fileContent: String = ""
    @State private var isLoadingContent = false
    @State private var isEditing = false
    @State private var editableContent: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let file = file {
                // Header with file info and controls
                fileHeader(file)
                
                Divider()
                
                // Content area
                if file.isDirectory {
                    directoryPreview(file)
                } else {
                    fileContentView(file)
                }
            } else {
                // No file selected placeholder
                emptyStateView
            }
        }
        .background(.background)
        .onChange(of: file) { _, newFile in
            if let newFile = newFile, !newFile.isDirectory {
                Task {
                    await loadFileContent(newFile)
                }
            }
        }
        .onChange(of: fileContent) { _, newContent in
            editableContent = newContent
        }
    }
    
    // MARK: - Header
    private func fileHeader(_ file: RemoteFile) -> some View {
        HStack {
            // File icon and name
            HStack(spacing: 8) {
                Image(systemName: fileIcon(for: file))
                    .foregroundStyle(file.isDirectory ? .blue : .primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(formatFileSize(file.size)) • Modified \(file.modificationDate.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            if !file.isDirectory {
                HStack(spacing: 8) {
                    // Edit/View toggle
                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: isEditing ? "eye" : "pencil")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .help(isEditing ? "View Mode" : "Edit Mode")
                    
                    // Download button
                    Button(action: { downloadFile(file) }) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .help("Download File")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
    
    // MARK: - Content Views
    private func fileContentView(_ file: RemoteFile) -> some View {
        Group {
            if isLoadingContent {
                loadingView
            } else if isCodeFile(file) {
                codeEditorView(file)
            } else if isImageFile(file) {
                imagePreview(file)
            } else {
                textPreview(file)
            }
        }
    }
    
    private func codeEditorView(_ file: RemoteFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Save button (only show when editing)
            if isEditing {
                HStack {
                    Spacer()
                    Button("Save") {
                        // TODO: Implement save functionality
                        fileContent = editableContent
                        logger.info("Save file: \(file.name)", category: .ui)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }

            // Professional code editor with syntax highlighting and line numbers
            RunestoneTextView(
                text: isEditing ? $editableContent : .constant(fileContent),
                filePath: file.path,
                isEditable: isEditing,
                font: .monospacedSystemFont(ofSize: 14, weight: .regular)
            )
            .background(.background)
        }
    }
    
    private func textPreview(_ file: RemoteFile) -> some View {
        ScrollView {
            Text(fileContent.isEmpty ? "Loading..." : fileContent)
                .font(.system(.body, design: .monospaced))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func imagePreview(_ file: RemoteFile) -> some View {
        VStack {
            Spacer()
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Image Preview")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Image preview not yet implemented")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
    
    private func directoryPreview(_ file: RemoteFile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Directory Contents")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // Directory contents would be loaded here
            Text("Directory preview not yet implemented")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading file content...")
                .progressViewStyle(.circular)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Select a file to preview")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Choose a file from the tree to view its contents")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    private func loadFileContent(_ file: RemoteFile) async {
        isLoadingContent = true
        defer { isLoadingContent = false }

        // File size protection - limit to 10MB for performance
        let maxFileSize: Int64 = 10 * 1024 * 1024
        if file.size > maxFileSize {
            fileContent = "File too large to preview\nFile: \(file.name)\nSize: \(formatFileSize(file.size))\nLimit: \(formatFileSize(maxFileSize))\n\nUse download to access large files."
            return
        }

        // Use real SFTP file reading
        if let data = await RemoteHostManager.shared.downloadFile(at: file.path) {
            if let content = String(data: data, encoding: .utf8) {
                fileContent = content
            } else if let content = String(data: data, encoding: .ascii) {
                fileContent = content
            } else {
                fileContent = "Binary file or unsupported encoding\nFile: \(file.name)\nSize: \(formatFileSize(file.size))\nModified: \(file.modificationDate.formatted())"
            }
        } else {
            fileContent = "Failed to load file content\nFile: \(file.name)\nPath: \(file.path)\n\nPlease check your connection and file permissions."
        }
    }

    // MARK: - File Type Detection
    private func isCodeFile(_ file: RemoteFile) -> Bool {
        return LanguageMapper.isCodeFile(file.name)
    }

    private func isImageFile(_ file: RemoteFile) -> Bool {
        return LanguageMapper.isImageFile(file.name)
    }

    private func fileIcon(for file: RemoteFile) -> String {
        return LanguageMapper.fileIcon(for: file.name, isDirectory: file.isDirectory)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func downloadFile(_ file: RemoteFile) {
        // TODO: Implement file download functionality
        logger.info("Download file: \(file.name)", category: .ui)
    }
}

#Preview {
    FilePreviewView(file: RemoteFile(
        name: "example.swift",
        path: "/root/example.swift",
        isDirectory: false,
        size: 1024,
        modificationDate: Date()
    ))
    .frame(width: 600, height: 400)
}

