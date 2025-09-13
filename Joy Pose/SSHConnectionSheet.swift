//
//  SSHConnectionSheet.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI
import Citadel

/// SSH connection configuration sheet
struct SSHConnectionSheet: View {
    @Bindable var hostManager: RemoteHostManager
    @Binding var savedHosts: [HostConfiguration]
    @Binding var isPresented: Bool
    
    // Form state
    @State private var hostName = ""
    @State private var hostname = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    
    // UI state
    @State private var isConnecting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var connectionLog = ""
    @State private var showConnectionLog = false
    
    // Edit mode
    let editingHost: HostConfiguration?
    
    init(hostManager: RemoteHostManager, savedHosts: Binding<[HostConfiguration]>, isPresented: Binding<Bool>, editingHost: HostConfiguration? = nil) {
        self._hostManager = Bindable(hostManager)
        self._savedHosts = savedHosts
        self._isPresented = isPresented
        self.editingHost = editingHost
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Connection form
                ScrollView {
                    VStack(spacing: 20) {
                        connectionFormSection
                        
                        if showConnectionLog {
                            connectionLogSection
                        }
                    }
                    .padding(20)
                }
                
                Divider()
                
                // Action buttons
                actionButtonsSection
                    .padding(20)
            }
            .navigationTitle(editingHost != nil ? "Edit Connection" : "Add SSH Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            loadEditingHost()
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Connection Form Section
    
    private var connectionFormSection: some View {
        VStack(spacing: 16) {
            // Host Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Connection Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("My Server", text: $hostName)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Hostname
            VStack(alignment: .leading, spacing: 4) {
                Text("Hostname")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("192.168.1.100", text: $hostname)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            // Port
            VStack(alignment: .leading, spacing: 4) {
                Text("Port")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("22", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            
            // Username
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("root", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            // Password
            VStack(alignment: .leading, spacing: 4) {
                Text("Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    if showPassword {
                        TextField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Connection Log Section
    
    private var connectionLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Connection Log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Clear") {
                    connectionLog = ""
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            ScrollView {
                Text(connectionLog.isEmpty ? "No logs yet..." : connectionLog)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(connectionLog.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 120)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Test Connection
            Button {
                Task {
                    await testConnection()
                }
            } label: {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "network")
                    }
                    Text("Test Connection")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isConnecting || hostname.isEmpty || username.isEmpty)
            
            // Save & Connect
            Button {
                Task {
                    await saveAndConnect()
                }
            } label: {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle")
                    }
                    Text(editingHost != nil ? "Update & Connect" : "Save & Connect")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isConnecting || hostName.isEmpty || hostname.isEmpty || username.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadEditingHost() {
        guard let host = editingHost else { return }
        
        hostName = host.name
        hostname = host.hostname
        port = String(host.port)
        username = host.username
        password = host.password
    }
    
    private func testConnection() async {
        isConnecting = true
        showConnectionLog = true
        connectionLog = "Testing connection to \(hostname):\(port)...\n"
        
        let config = HostConfiguration(
            name: hostName.isEmpty ? "Test" : hostName,
            hostname: hostname,
            port: Int(port) ?? 22,
            username: username,
            password: password
        )
        
        let success = await testConnectionWith(config)
        
        await MainActor.run {
            isConnecting = false
            if success {
                connectionLog += "✅ Connection test successful!\n"
            } else {
                connectionLog += "❌ Connection test failed.\n"
                showError = true
                errorMessage = "Failed to connect to \(hostname). Please check your credentials and network connection."
            }
        }
    }
    
    private func saveAndConnect() async {
        isConnecting = true
        showConnectionLog = true
        connectionLog = "Saving configuration and connecting...\n"
        
        let config = HostConfiguration(
            name: hostName,
            hostname: hostname,
            port: Int(port) ?? 22,
            username: username,
            password: password
        )
        
        // Save or update host configuration
        if let editingHost = editingHost,
           let index = savedHosts.firstIndex(where: { $0.id == editingHost.id }) {
            savedHosts[index] = config
        } else {
            savedHosts.append(config)
        }
        
        // Connect to the host
        await hostManager.connect(to: config)
        
        await MainActor.run {
            isConnecting = false
            if hostManager.connectionState == .connected {
                connectionLog += "✅ Connected successfully!\n"
                // Close sheet after successful connection
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isPresented = false
                }
            } else {
                connectionLog += "❌ Connection failed.\n"
                showError = true
                errorMessage = "Failed to connect to \(hostname). Please check your credentials."
            }
        }
    }
    
    private func testConnectionWith(_ config: HostConfiguration) async -> Bool {
        // Create a temporary connection test
        do {
            logger.info("Testing SSH connection to \(config.hostname):\(config.port)", category: .connection)
            
            // Use a simple connection test approach
            let settings = SSHClientSettings(
                host: config.hostname,
                port: config.port,
                authenticationMethod: { SSHAuthenticationMethod.passwordBased(username: config.username, password: config.password) },
                hostKeyValidator: SSHHostKeyValidator.acceptAnything()
            )
            
            let client = try await SSHClient.connect(to: settings)
            try await client.close()
            
            return true
        } catch {
            logger.error("Connection test failed: \(error.localizedDescription)", category: .connection)
            return false
        }
    }
}