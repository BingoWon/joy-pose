//
//  SSHTerminalSession.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import SwiftUI
import Citadel

/// Independent terminal session for each terminal window
@Observable
class SSHTerminalSession {
    // Session identification
    let sessionId = UUID()
    
    // Connection state
    var connectionState: ConnectionState = .disconnected
    
    // Terminal output and history
    var terminalOutput: [String] = []
    var commandHistory: [String] = []
    
    // SSH connection components
    private var sshClient: SSHClient?
    
    // Current working directory
    var currentDirectory = "~"
    
    init() {
        logger.info("Created new terminal session: \(sessionId)", category: .terminal)
    }
    
    deinit {
        Task {
            await disconnect()
        }
        logger.info("Terminal session destroyed: \(sessionId)", category: .terminal)
    }
    
    /// Connect to SSH server using current host configuration
    @MainActor
    func connectToHost() async {
        guard let hostConfig = RemoteHostManager.shared.currentHost else {
            logger.error("No host configuration available", category: .terminal)
            return
        }
        
        await connectToHost(hostConfig)
    }
    
    /// Connect to specific SSH server
    @MainActor
    func connectToHost(_ hostConfig: HostConfiguration) async {
        guard connectionState != .connected && connectionState != .connecting else {
            logger.warning("Session \(sessionId) already connected or connecting", category: .terminal)
            return
        }
        
        connectionState = .connecting
        logger.info("Session \(sessionId): Starting SSH connection to \(hostConfig.hostname):\(hostConfig.port) as \(hostConfig.username)", category: .terminal)
        
        do {
            // Create SSH client settings
            let settings = SSHClientSettings(
                host: hostConfig.hostname,
                port: hostConfig.port,
                authenticationMethod: { .passwordBased(username: hostConfig.username, password: hostConfig.password) },
                hostKeyValidator: .acceptAnything()
            )

            // Connect to SSH server
            sshClient = try await SSHClient.connect(to: settings)
            
            connectionState = .connected
            logger.info("Session \(sessionId): SSH connection established successfully", category: .terminal)
            
            // Add welcome message
            await addOutput("Connected to \(hostConfig.hostname) as \(hostConfig.username)")
            await addOutput("Session ID: \(sessionId.uuidString.prefix(8))")
            await addOutput("")
            
            // Get initial working directory
            await executeCommand("pwd", addToHistory: false)
            
        } catch {
            connectionState = .failed(error.localizedDescription)
            logger.error("Session \(sessionId): SSH connection failed: \(error)", category: .terminal)
            await addOutput("Connection failed: \(error.localizedDescription)")
        }
    }
    
    /// Disconnect from SSH server
    func disconnect() async {
        guard connectionState == .connected else { return }
        
        logger.info("Session \(sessionId): Disconnecting SSH connection", category: .terminal)
        
        connectionState = .disconnected
        
        try? await sshClient?.close()
        sshClient = nil
        
        await addOutput("Disconnected from server")
    }
    
    /// Execute command on remote server
    @MainActor
    func executeCommand(_ command: String, addToHistory: Bool = true) async {
        guard connectionState == .connected, let sshClient = sshClient else {
            await addOutput("Error: Not connected to server")
            return
        }
        
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        if addToHistory {
            // Add to command history
            if commandHistory.last != command {
                commandHistory.append(command)
            }
            
            // Add command to output
            await addOutput("$ \(command)")
        }
        
        logger.debug("Session \(sessionId): Command executed: \(command)", category: .terminal)
        
        do {
            let output = try await sshClient.executeCommand(command)
            let outputString = String(buffer: output)

            if !outputString.isEmpty {
                await addOutput(outputString)
            }
            
            // Update current directory if it's a cd command or pwd command
            if command.hasPrefix("cd ") {
                await executeCommand("pwd", addToHistory: false)
            } else if command == "pwd" && !outputString.isEmpty {
                currentDirectory = outputString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
        } catch {
            await addOutput("Error executing command: \(error.localizedDescription)")
            logger.error("Session \(sessionId): Command execution failed: \(error)", category: .terminal)
        }
    }
    
    /// Add output to terminal
    @MainActor
    private func addOutput(_ text: String) async {
        let lines = text.components(separatedBy: .newlines)
        terminalOutput.append(contentsOf: lines)
        
        // Keep only last 1000 lines to prevent memory issues
        if terminalOutput.count > 1000 {
            terminalOutput.removeFirst(terminalOutput.count - 1000)
        }
    }
    
    /// Clear terminal output
    @MainActor
    func clearOutput() {
        terminalOutput.removeAll()
    }
    
    /// Clear terminal output (alias for clearOutput)
    @MainActor
    func clearTerminal() {
        clearOutput()
        logger.info("Session \(sessionId): Terminal cleared", category: .terminal)
    }
    
    /// Get command from history
    func getHistoryCommand(at index: Int) -> String? {
        guard index >= 0 && index < commandHistory.count else { return nil }
        return commandHistory[index]
    }
    
    /// Get terminal output as single string
    var outputText: String {
        terminalOutput.joined(separator: "\n")
    }
}
