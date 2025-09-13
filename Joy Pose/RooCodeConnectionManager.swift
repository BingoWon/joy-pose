//
//  RooCodeConnectionManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import Combine
import SwiftUI

/// Roo Code 专用连接管理器 - 负责与 Roo Code 的 WebSocket 连接
@MainActor
@Observable
final class RooCodeConnectionManager {
    // MARK: - Singleton
    static let shared = RooCodeConnectionManager()

    private(set) var currentService: RooCodeService?
    private(set) var currentEditorState: EditorState?

    // Direct exposure of sub-components - @Observable handles dependency tracking automatically
    let serviceDiscovery = RooCodeDiscoveryService()
    let webSocketClient = WebSocketClient()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupMessageHandling()
    }

    /// Setup message handling - Pure @Observable pattern
    private func setupMessageHandling() {
        // 只保留必要的消息流处理
        webSocketClient.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleMessage(message)
            }
            .store(in: &cancellables)
    }

    /// Auto-connect to first discovered service - Simplified logic with error handling
    func autoConnectIfNeeded() {
        // 只在未连接且有可用服务时自动连接
        guard !connectionState.isConnected,
              currentService == nil,
              !discoveredServices.isEmpty else { 
            logger.info("🔍 [DEBUG] autoConnectIfNeeded: Skip - isConnected: \(connectionState.isConnected), currentService: \(currentService?.name ?? "nil"), services: \(discoveredServices.count)", category: .connection)
            return 
        }

        let bestService = discoveredServices.first!
        logger.info("🔍 [DEBUG] autoConnectIfNeeded: Starting auto-connection to \(bestService.name) at \(bestService.websocketURL)", category: .connection)

        Task {
            await connect(to: bestService)
            // 连接失败会通过webSocketClient.connectionState自动反映，无需手动设置
        }
    }

    /// Start service discovery - Simplified with timeout
    func startScanning() {
        serviceDiscovery.startScanning(preserveServices: connectionState.isConnected)

        // 扫描完成后自动连接（如果需要），添加超时保护
        Task { @MainActor in
            var waitTime = 0
            let maxWaitTime = 15000 // 15秒超时，给网络扫描足够时间

            // 等待扫描完成，但不超过15秒
            while serviceDiscovery.isScanning && waitTime < maxWaitTime {
                try? await Task.sleep(for: .milliseconds(100))
                waitTime += 100
            }

            logger.info("🔍 [DEBUG] startScanning: Scan wait completed - isScanning: \(serviceDiscovery.isScanning), waitTime: \(waitTime)ms, services: \(discoveredServices.count)", category: .connection)

            // 无论扫描是否完成，都尝试自动连接（如果有服务的话）
            autoConnectIfNeeded()
        }
    }

    /// Stop service discovery
    func stopScanning() { serviceDiscovery.stopScanning() }

    /// Refresh available services
    func refreshServices() {
        serviceDiscovery.stopScanning()
        serviceDiscovery.startScanning(preserveServices: false)
    }

    /// Connect to a Roo Code service
    func connect(to service: RooCodeService) async {
        logger.info("🔍 [DEBUG] connect: Attempting to connect to \(service.name) at \(service.websocketURL)", category: .connection)
        currentService = service
        webSocketClient.clearError()
        await webSocketClient.connect(to: service)

        // 连接成功后停止扫描
        if webSocketClient.connectionState.isConnected {
            logger.info("🔍 [DEBUG] connect: Successfully connected to \(service.name), stopping service discovery", category: .connection)
            serviceDiscovery.stopScanning()
        } else {
            logger.warning("🔍 [DEBUG] connect: Failed to connect to \(service.name), state: \(webSocketClient.connectionState.description)", category: .connection)
        }
    }

    /// Disconnect from current service
    func disconnect() {
        webSocketClient.disconnect()
        currentService = nil
        currentEditorState = nil
    }

    /// Clear errors
    func clearError() {
        webSocketClient.clearError()
    }

    /// Handle incoming messages - 现代化处理
    private func handleMessage(_ message: VisionMessage) {
        switch message.type {
        case .connectionAccepted:
            // 连接已在 WebSocketClient 中处理
            break
        case .aiConversation:
            // AI 对话消息转发给相应的管理器
            break
        default:
            break
        }
    }
}

// MARK: - Computed Properties - Pure @Observable Pattern
extension RooCodeConnectionManager {
    // 直接访问子组件属性 - @Observable 自动处理精确依赖跟踪
    var discoveredServices: [RooCodeService] { serviceDiscovery.discoveredServices }
    var isScanning: Bool { serviceDiscovery.isScanning }
    var connectionState: RooCodeConnectionState { webSocketClient.connectionState }
    var isConnected: Bool { connectionState.isConnected }

    // 精确的错误状态 - 避免过于宽泛的依赖
    var connectionError: String? { webSocketClient.lastError }
    var discoveryError: String? { serviceDiscovery.error }

    var connectionStatusText: String {
        if let service = currentService {
            return "\(connectionState.description) - \(service.displayName)"
        }
        return connectionState.description
    }

    var currentFileInfo: String {
        guard let state = currentEditorState else { return "No file open" }
        let fileName = state.filePath?.components(separatedBy: "/").last ?? "Unknown"
        return "\(fileName) - Line \(state.cursorLine), Column \(state.cursorColumn)"
    }

    func connectionStatusColor() -> Color {
        switch connectionState {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .gray
        case .failed: return .red
        }
    }

    func connectionStatusIcon() -> String {
        switch connectionState {
        case .connected: return "checkmark.circle.fill"
        case .connecting: return "arrow.clockwise.circle.fill"
        case .disconnected: return "circle"
        case .failed: return "xmark.circle.fill"
        }
    }
}
