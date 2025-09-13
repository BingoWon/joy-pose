//
//  RemoteFileManagerView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct RemoteFileManagerView: View {
    @State private var windowManager = WindowManager.shared
    @State private var files: [String] = ["Documents", "Downloads", "Pictures", "Music", "readme.txt", "config.json"]

    var body: some View {
        NavigationView {
            // File List
            List {
                ForEach(files, id: \.self) { file in
                    HStack {
                        Image(systemName: file.contains(".") ? "doc.text" : "folder")
                            .foregroundStyle(.blue)
                        
                        Text(file)
                            .font(.system(.body, design: .default))
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Remote Files")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        // Refresh file list
                    }
                }
            }

            // File Preview
            VStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("Select a file to preview")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
        }
        .onDisappear {
            windowManager.disableRemoteFileManager()
        }
    }
}
