//
//  MainControlView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

/// Main control view - manages application windows and remote development tools
struct MainControlView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(AppModel.self) private var appModel

    @State private var windowManager = WindowManager.shared
    @State private var hostManager = RemoteHostManager.shared
    @State private var rooCodeConnectionManager = RooCodeConnectionManager.shared

    // SSH Connection UI state
    @State private var showConnectionSheet = false
    @State private var editingHost: HostConfiguration?

    // Saved hosts
    @State private var savedHosts: [HostConfiguration] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Hero Header Section
                        heroHeaderSection
                            .padding(.horizontal, 32)
                            .padding(.top, 24)

                        // Main Content
                        VStack(spacing: 32) {
                            // Status Overview Cards
                            statusOverviewSection

                            // Feature Grid
                            featureGridSection

                            // Quick Actions
                            quickActionsSection
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 32)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(minWidth: 1000, maxWidth: 1400, minHeight: 900)
        .onAppear {
            loadSavedHosts()
            print("🎯 JoyPose main control view displayed")
        }
        .onChange(of: savedHosts) { _, _ in
            saveSavedHosts()
        }
        .onChange(of: hostManager.connectionState) { _, newState in
            windowManager.handleConnectionStateChange(newState)
        }
        .sheet(isPresented: $showConnectionSheet) {
            SSHConnectionSheet(
                hostManager: hostManager,
                savedHosts: $savedHosts,
                isPresented: $showConnectionSheet,
                editingHost: editingHost
            )
        }
    }

    // MARK: - Hero Header Section

    private var heroHeaderSection: some View {
        VStack(spacing: 24) {
            // Main Title and Subtitle
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.blue.gradient)

                    Text("JoyPose")
                        .font(.system(size: 42, weight: .thin, design: .default))
                        .foregroundStyle(.primary)

                    Spacer()
                }

                HStack {
                    Text("Intelligent Development Environment")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            // Connection Status Banner
            connectionStatusBanner
        }
    }

    private var connectionStatusBanner: some View {
        HStack(spacing: 16) {
            // Roo Code Status
            HStack(spacing: 8) {
                Circle()
                    .fill(rooCodeConnectionColor.gradient)
                    .frame(width: 8, height: 8)

                Text("AI Assistant")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(rooCodeConnectionManager.connectionState.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 16)

            // SSH Status
            HStack(spacing: 8) {
                Circle()
                    .fill(connectionStatusColor.gradient)
                    .frame(width: 8, height: 8)

                Text("Remote Host")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let host = hostManager.currentHost {
                    Text("\(host.username)@\(host.hostname)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not Connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Status Overview Section

    private var statusOverviewSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            // AI Assistant Card
            aiAssistantStatusCard

            // Remote Host Card
            remoteHostStatusCard
        }
    }

    private var aiAssistantStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Assistant")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(rooCodeConnectionManager.connectionState.displayText)
                        .font(.subheadline)
                        .foregroundStyle(rooCodeConnectionColor)
                }

                Spacer()

                // Status indicator with animation
                Circle()
                    .fill(rooCodeConnectionColor.gradient)
                    .frame(width: 12, height: 12)
                    .scaleEffect(rooCodeConnectionManager.isConnected ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: rooCodeConnectionManager.isConnected)
            }

            // Description
            Text(rooCodeConnectionStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Action Buttons
            HStack(spacing: 8) {
                if rooCodeConnectionManager.isConnected {
                    Button(action: {
                        if windowManager.isAIAgentsOpen {
                            dismissWindow(id: "ai-agents")
                            windowManager.disableAIAgents()
                        } else {
                            windowManager.enableAIAgents()
                            openWindow(id: "ai-agents")
                        }
                    }) {
                        HStack {
                            Image(systemName: windowManager.isAIAgentsOpen ? "xmark.circle" : "plus.circle")
                            Text(windowManager.isAIAgentsOpen ? "Close AI Agents" : "Open AI Agents")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(windowManager.isAIAgentsOpen ? .red : .blue)
                    .controlSize(.small)
                } else {
                    // 连接失败或断开时显示重新连接按钮
                    Button(action: {
                        Task {
                            await reconnectToRooCode()
                        }
                    }) {
                        HStack {
                            Image(systemName: rooCodeConnectionManager.connectionState == .connecting ? "arrow.clockwise" : "arrow.clockwise.circle")
                            Text(rooCodeConnectionManager.connectionState == .connecting ? "Scanning..." : "Reconnect")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                    .disabled(rooCodeConnectionManager.connectionState == .connecting)
                    
                    // 如果连接失败，显示更多选项菜单
                    if case .failed = rooCodeConnectionManager.connectionState {
                        Menu {
                            Button("Refresh Services") {
                                rooCodeConnectionManager.refreshServices()
                            }
                            
                            Button("Clear Error") {
                                rooCodeConnectionManager.clearError()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rooCodeConnectionColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var remoteHostStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "server.rack")
                    .font(.title2)
                    .foregroundStyle(connectionStatusColor.gradient)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Remote Host")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(connectionStatusText)
                        .font(.subheadline)
                        .foregroundStyle(connectionStatusColor)
                }

                Spacer()

                // Status indicator with animation
                Circle()
                    .fill(connectionStatusColor.gradient)
                    .frame(width: 12, height: 12)
                    .scaleEffect(hostManager.connectionState == .connecting ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: hostManager.connectionState == .connecting)
            }

            // Connection Info or Quick Connect
            if hostManager.connectionState == .connected, let host = hostManager.currentHost {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connected to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(host.username)@\(host.hostname):\(host.port)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            } else {
                Text("Connect to a remote server for development")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Action Buttons
            HStack(spacing: 8) {
                if hostManager.connectionState == .connected {
                    Button("Disconnect") {
                        Task {
                            await hostManager.disconnect()
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                } else {
                    Button("Connect") {
                        showConnectionSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                }

                if !savedHosts.isEmpty {
                    Menu {
                        ForEach(savedHosts, id: \.id) { host in
                            Button("\(host.username)@\(host.hostname)") {
                                Task {
                                    await hostManager.connect(to: host)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(connectionStatusColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var connectionStatusColor: Color {
        statusColor(for: hostManager.connectionState)
    }

    private var connectionStatusText: String {
        statusText(for: hostManager.connectionState)
    }

    private func statusColor(for state: ConnectionState) -> Color {
        switch state {
        case .disconnected: return .orange
        case .connecting: return .blue
        case .connected: return .green
        case .failed: return .red
        }
    }

    private func statusText(for state: ConnectionState) -> String {
        switch state {
        case .disconnected: return "Not Connected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .failed: return "Connection Failed"
        }
    }

    // MARK: - Feature Grid Section

    private var featureGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Development Tools")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                // Remote Terminal
                if hostManager.connectionState == .connected {
                    featureCard(
                        icon: "terminal",
                        title: "Remote Terminal",
                        description: "Access remote command line",
                        color: .green,
                        isAvailable: true
                    ) {
                        if windowManager.isRemoteTerminalOpen {
                            dismissWindow(id: "remote-terminal")
                            windowManager.disableRemoteTerminal()
                        } else {
                            windowManager.enableRemoteTerminal()
                            openWindow(id: "remote-terminal")
                        }
                    }

                    // File Manager
                    featureCard(
                        icon: "folder",
                        title: "File Manager",
                        description: "Browse remote files",
                        color: .blue,
                        isAvailable: true
                    ) {
                        if windowManager.isRemoteFileManagerOpen {
                            dismissWindow(id: "remote-file-manager")
                            windowManager.disableRemoteFileManager()
                        } else {
                            windowManager.enableRemoteFileManager()
                            openWindow(id: "remote-file-manager")
                        }
                    }
                }
            }
        }
    }

    private func featureCard(
        icon: String,
        title: String,
        description: String,
        color: Color,
        isAvailable: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isAvailable ? color : Color.secondary)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAvailable ? color.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }

    // MARK: - Helper Methods
    
    /// 重新连接到 Roo Code 服务
    private func reconnectToRooCode() async {
        logger.info("User triggered Roo Code reconnection", category: .connection)
        
        // 先断开现有连接
        rooCodeConnectionManager.disconnect()
        
        // 清除错误状态
        rooCodeConnectionManager.clearError()
        
        // 重新开始扫描和连接
        rooCodeConnectionManager.startScanning()
    }

    // MARK: - Helper Properties

    private var rooCodeConnectionColor: Color {
        rooCodeStatusColor(for: rooCodeConnectionManager.connectionState)
    }

    private func rooCodeStatusColor(for state: RooCodeConnectionState) -> Color {
        switch state {
        case .connected: return .green
        case .connecting: return .blue
        case .disconnected: return .gray
        case .failed: return .red
        }
    }

    private var rooCodeConnectionStatusText: String {
        if rooCodeConnectionManager.isConnected {
            return "AI conversation interface is ready. Open AI Agents window to start chatting."
        } else {
            return "Connect to Roo Code server to enable AI-powered conversations and code assistance."
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                // Add New Host
                quickActionButton(
                    icon: "plus.circle",
                    title: "Add Host",
                    color: .blue
                ) {
                    editingHost = nil
                    showConnectionSheet = true
                }

                // Refresh Connections
                quickActionButton(
                    icon: "arrow.clockwise",
                    title: "Refresh",
                    color: .green
                ) {
                    // Refresh logic here
                    loadSavedHosts()
                }

                Spacer()

                // Settings (placeholder for future)
                quickActionButton(
                    icon: "gearshape",
                    title: "Settings",
                    color: .gray
                ) {
                    // Settings action placeholder
                }
            }
        }
    }

    private func quickActionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func loadSavedHosts() {
        if let data = UserDefaults.standard.data(forKey: "SavedSSHHosts") {
            do {
                let hosts = try JSONDecoder().decode([HostConfiguration].self, from: data)
                savedHosts = hosts
                print("🎯 Loaded \(hosts.count) saved SSH hosts")
            } catch {
                print("❌ Failed to load saved SSH hosts: \(error.localizedDescription)")
                savedHosts = []
            }
        } else {
            savedHosts = []
            print("🎯 No saved SSH hosts found")
        }
    }

    private func saveSavedHosts() {
        do {
            let data = try JSONEncoder().encode(savedHosts)
            UserDefaults.standard.set(data, forKey: "SavedSSHHosts")
            print("🎯 Saved \(savedHosts.count) SSH hosts to UserDefaults")
        } catch {
            print("❌ Failed to save SSH hosts: \(error.localizedDescription)")
        }
    }
}

#Preview {
    MainControlView()
}