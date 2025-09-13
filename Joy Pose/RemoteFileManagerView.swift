//
//  RemoteFileManagerView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// Modern VSCode-style remote file manager with optimized architecture
struct RemoteFileManagerView: View {
    @State private var hostManager = RemoteHostManager.shared
    @State private var windowManager = WindowManager.shared
    @State private var fileTreeManager = FileTreeManager()
    @State private var selectedFile: RemoteFile?
    @State private var showingFileImporter = false
    @State private var showingDeleteAlert = false
    @State private var fileToDelete: RemoteFile?

    var body: some View {
        connectedLayout
        .navigationTitle("Remote File Manager")
        .toolbar { toolbarContent }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .alert("Delete File", isPresented: $showingDeleteAlert, presenting: fileToDelete) { file in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { try? await hostManager.deleteFile(file) }
            }
        } message: { file in
            Text("Are you sure you want to delete '\(file.name)'? This action cannot be undone.")
        }
        .onDisappear {
            // Update window manager state when window is closed
            windowManager.disableRemoteFileManager()
        }
    }

    private var connectedLayout: some View {
        HStack(spacing: 0) {
            FileTreeSidebar(
                fileTreeManager: fileTreeManager,
                hostManager: hostManager,
                selectedFile: $selectedFile
            )

            Divider()

            FilePreviewView(file: selectedFile)
                .frame(minWidth: 400)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu("Sort", systemImage: "arrow.up.arrow.down") {
                ForEach(FileTreeManager.SortOrder.allCases, id: \.self) { order in
                    Button(order.displayName) {
                        fileTreeManager.sortOrder = order
                    }
                }
            }

            Button("Upload", systemImage: "square.and.arrow.up") {
                showingFileImporter = true
            }
        }
    }

    // MARK: - File Operations

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                for url in urls {
                    do {
                        let data = try Data(contentsOf: url)
                        let success = await hostManager.uploadFile(
                            data: data,
                            to: hostManager.currentDirectory + "/" + url.lastPathComponent
                        )
                        if !success {
                            logger.error("Failed to upload file: \(url.lastPathComponent)", category: .ui)
                        }
                    } catch {
                        logger.error("Upload failed for \(url): \(error)", category: .ui)
                    }
                }
            }
        case .failure(let error):
            logger.error("File import failed: \(error)", category: .ui)
        }
    }
}

#Preview {
    RemoteFileManagerView()
        .frame(width: 1200, height: 800)
}