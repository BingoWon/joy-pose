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
    
    // Ornament states
    @State private var showQuickCommands = false
    @State private var showNetworkTools = false
    @State private var showDebugPanel = false
    
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
        .overlay {
            if showDebugPanel {
                debugFloatingPanel
            }
        }
        .ornament(
            visibility: showQuickCommands ? .visible : .hidden,
            attachmentAnchor: .scene(.bottom),
            contentAlignment: .top
        ) {
            quickCommandsOrnament
        }
        .ornament(
            visibility: showNetworkTools ? .visible : .hidden,
            attachmentAnchor: .scene(.topTrailing),
            contentAlignment: .trailing
        ) {
            networkToolsOrnament
        }
        .background(
            RemoteTerminalViewControllerRepresentable(
                showQuickCommands: $showQuickCommands,
                showNetworkTools: $showNetworkTools,
                showDebugPanel: $showDebugPanel
            )
        )
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

// MARK: - Ornament Views

extension RemoteTerminalView {
    
    private var quickCommandsOrnament: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Commands")
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                QuickCommandButton(title: "List Files", icon: "list.bullet", command: "ls -la")
                QuickCommandButton(title: "Current Dir", icon: "folder", command: "pwd")
                QuickCommandButton(title: "Disk Usage", icon: "internaldrive", command: "df -h")
                QuickCommandButton(title: "Memory", icon: "memorychip", command: "free -h")
                QuickCommandButton(title: "Processes", icon: "cpu", command: "ps aux")
                QuickCommandButton(title: "Network", icon: "network", command: "netstat -tuln")
                QuickCommandButton(title: "System Info", icon: "info.circle", command: "uname -a")
                QuickCommandButton(title: "Clear", icon: "trash", command: "clear")
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .glassBackgroundEffect()
        .frame(width: 280)
    }

    private var networkToolsOrnament: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Network Tools")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 6) {
                Button("Ping Test") {
                    // UI only - no functionality
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("DNS Lookup") {
                    // UI only - no functionality
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Network Info") {
                    // UI only - no functionality
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("SSH Info") {
                    // UI only - no functionality
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .glassBackgroundEffect()
        .frame(width: 160)
    }

    private var debugFloatingPanel: some View {
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showDebugPanel = false
                }

            // Centered debug panel
            ControllerDebugView(onClose: {
                showDebugPanel = false
            })
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(showDebugPanel ? 1.0 : 0.8)
            .opacity(showDebugPanel ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showDebugPanel)
        }
    }
}

// MARK: - UIHostingOrnament Implementation

struct RemoteTerminalViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var showQuickCommands: Bool
    @Binding var showNetworkTools: Bool
    @Binding var showDebugPanel: Bool

    func makeUIViewController(context: Context) -> RemoteTerminalViewController {
        let controller = RemoteTerminalViewController()
        
        controller.onShowQuickCommandsChanged = { value in
            showQuickCommands = value
        }
        controller.onShowNetworkToolsChanged = { value in
            showNetworkTools = value
        }
        controller.onShowDebugPanelChanged = { value in
            showDebugPanel = value
        }
        
        return controller
    }

    func updateUIViewController(_ uiViewController: RemoteTerminalViewController, context: Context) {
        uiViewController.showQuickCommands = showQuickCommands
        uiViewController.showNetworkTools = showNetworkTools
        uiViewController.showDebugPanel = showDebugPanel
    }
}

class RemoteTerminalViewController: UIViewController {
    var showQuickCommands: Bool = false {
        didSet { updateOrnaments() }
    }
    var showNetworkTools: Bool = false {
        didSet { updateOrnaments() }
    }
    var showDebugPanel: Bool = false {
        didSet { updateOrnaments() }
    }

    var onShowQuickCommandsChanged: ((Bool) -> Void)?
    var onShowNetworkToolsChanged: ((Bool) -> Void)?
    var onShowDebugPanelChanged: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        updateOrnaments()
    }

    func updateOrnaments() {
        var newOrnaments: [UIHostingOrnament<AnyView>] = []

        // Bottom buttons ornament - designed for remote terminal
        let bottomOrnament = UIHostingOrnament(
            sceneAnchor: .bottom,
            contentAlignment: .top
        ) {
            AnyView(
                HStack(spacing: 12) {
                    Button(action: {
                        self.showQuickCommands.toggle()
                        self.onShowQuickCommandsChanged?(self.showQuickCommands)
                    }) {
                        Label("Remote Commands", systemImage: "terminal.fill")
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        self.showNetworkTools.toggle()
                        self.onShowNetworkToolsChanged?(self.showNetworkTools)
                    }) {
                        Label("Network", systemImage: "network")
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        self.showDebugPanel.toggle()
                        self.onShowDebugPanelChanged?(self.showDebugPanel)
                    }) {
                        Label(
                            self.showDebugPanel ? "Hide Debug" : "Show Debug",
                            systemImage: self.showDebugPanel ? "gamecontroller.fill" : "gamecontroller"
                        )
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(self.showDebugPanel ? .green : .primary)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .glassBackgroundEffect()
            )
        }

        newOrnaments.append(bottomOrnament)
        self.ornaments = newOrnaments
    }
}

// MARK: - Quick Command Button Component

struct QuickCommandButton: View {
    let title: String
    let icon: String
    let command: String

    var body: some View {
        Button(action: {
            // UI only - no functionality
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(command)
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