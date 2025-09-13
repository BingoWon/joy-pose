//
//  RemoteTerminalView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct RemoteTerminalView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var terminalSession = SSHTerminalSession()
    @State private var windowManager = WindowManager.shared

    // Terminal state
    @State private var currentCommand = ""
    @State private var commandHistoryIndex = -1

    // UI state
    @State private var isCommandFieldFocused = false
    @FocusState private var isInputFocused: Bool
    @FocusState private var isWindowFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal Management Section
            terminalManagementSection

            Divider()

            // Header
            headerSection

            Divider()

            // Terminal content
            connectedTerminalView
        }
        .background(.black)
        .foregroundStyle(.green)
        .font(.system(.body, design: .monospaced))
        .focused($isWindowFocused)
        .onAppear {
            isWindowFocused = true
            isInputFocused = true
        }
        .onAppear {
            // Auto-connect when terminal window appears
            Task {
                await terminalSession.connectToHost()
            }
        }
        .onDisappear {
            windowManager.disableRemoteTerminal()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Control Center") {
                    // Open main control window
                }
                .buttonStyle(.bordered)
                .help("Open main control window")
            }
        }
    }

    // MARK: - Terminal Management Section
    private var terminalManagementSection: some View {
        HStack {
            // Terminal session indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(.green.gradient)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Terminal Session")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("ID: \(terminalSession.sessionId.uuidString.prefix(8))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fontDesign(.monospaced)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button(action: clearTerminal) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Clear")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Clear terminal output")

                Button(action: openNewTerminal) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("New")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green.gradient, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Open new terminal window")

                Button(action: closeCurrentTerminal) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Close")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Close this terminal window")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // Connection status
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    if let host = RemoteHostManager.shared.currentHost {
                        Text("\(host.username)@\(host.hostname)")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(terminalSession.currentDirectory)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Connected Terminal View
    private var connectedTerminalView: some View {
        VStack(spacing: 0) {
            // Terminal output
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(terminalSession.terminalOutput.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .id("terminal-output")
                    }
                }
                .onChange(of: terminalSession.terminalOutput) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("terminal-output", anchor: .bottom)
                    }
                }
            }
            
            Divider()
                .background(.green.opacity(0.3))
            
            // Command input
            commandInputSection
        }
    }
    
    private var commandInputSection: some View {
        HStack(spacing: 8) {
            // Prompt
            if let host = RemoteHostManager.shared.currentHost {
                Text("\(host.username)@\(host.hostname):\(terminalSession.currentDirectory)$")
                    .foregroundStyle(.green)
            }
            
            // Command input
            TextField("Enter command...", text: $currentCommand)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .onSubmit {
                    executeCommand()
                }
                .onKeyPress(.upArrow) {
                    navigateCommandHistory(direction: .up)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    navigateCommandHistory(direction: .down)
                    return .handled
                }
            
            // Send button
            Button("Send") {
                executeCommand()
            }
            .buttonStyle(.bordered)
            .disabled(currentCommand.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .background(.black.opacity(0.8))
    }
    
    // MARK: - Actions
    private func executeCommand() {
        let command = currentCommand.trimmingCharacters(in: .whitespaces)
        guard !command.isEmpty else { return }

        Task {
            await terminalSession.executeCommand(command)
        }

        currentCommand = ""
        commandHistoryIndex = -1

        // Keep input focused
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFocused = true
        }
    }

    // MARK: - Terminal Management Actions
    private func openNewTerminal() {
        // Open a new terminal window using the same window group
        openWindow(id: "remote-terminal")
        logger.info("Opening new terminal window", category: .ui)
    }

    private func clearTerminal() {
        Task {
            await terminalSession.clearTerminal()
        }
        logger.info("Terminal cleared for session: \(terminalSession.sessionId)", category: .ui)
    }

    private func closeCurrentTerminal() {
        // Close the current terminal window
        dismissWindow(id: "remote-terminal")
        windowManager.disableRemoteTerminal()
        logger.info("Closing current terminal window", category: .ui)
    }
    
    private func navigateCommandHistory(direction: TerminalHistoryDirection) {
        let history = terminalSession.commandHistory
        guard !history.isEmpty else { return }

        switch direction {
        case .up:
            if commandHistoryIndex == -1 {
                commandHistoryIndex = history.count - 1
            } else if commandHistoryIndex > 0 {
                commandHistoryIndex -= 1
            }
        case .down:
            if commandHistoryIndex < history.count - 1 {
                commandHistoryIndex += 1
            } else {
                commandHistoryIndex = -1
                currentCommand = ""
                return
            }
        }

        if commandHistoryIndex >= 0 && commandHistoryIndex < history.count {
            currentCommand = history[commandHistoryIndex]
        }
    }
}

// MARK: - Supporting Types

private enum TerminalHistoryDirection {
    case up, down
}

#Preview {
    RemoteTerminalView()
        .frame(width: 1000, height: 700)
}