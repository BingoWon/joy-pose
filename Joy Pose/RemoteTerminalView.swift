//
//  RemoteTerminalView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct RemoteTerminalView: View {
    @State private var windowManager = WindowManager.shared
    @State private var terminalOutput: [String] = ["Welcome to JoyPose Remote Terminal", "Connected to remote host", ""]
    @State private var currentCommand = ""

    var body: some View {
        VStack(spacing: 0) {
            // Terminal Output
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(terminalOutput.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                }
                .padding()
            }
            .background(Color.black.opacity(0.9))
            .foregroundStyle(.green)

            Divider()

            // Command Input
            HStack {
                Text("$")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.green)

                TextField("Enter command...", text: $currentCommand)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.plain)
                    .onSubmit {
                        executeCommand()
                    }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Remote Terminal")
        .onDisappear {
            windowManager.disableRemoteTerminal()
        }
    }

    private func executeCommand() {
        guard !currentCommand.isEmpty else { return }
        
        terminalOutput.append("$ \(currentCommand)")
        
        // Simulate command execution
        switch currentCommand.lowercased() {
        case "ls":
            terminalOutput.append("Documents  Downloads  Pictures  Music")
        case "pwd":
            terminalOutput.append("/Users/remote")
        case "whoami":
            terminalOutput.append("remote")
        default:
            terminalOutput.append("Command '\(currentCommand)' not found")
        }
        
        terminalOutput.append("")
        currentCommand = ""
    }
}
