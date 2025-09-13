//
//  RooCodeMessages.swift
//  Joy Pose
//
//  VisionSync Protocol - Modern Unified Implementation
//

import Foundation

// MARK: - Core Protocol Types

/// VisionSync 消息类型 - 与服务端完全统一
enum MessageType: String, Codable {
    case clientHandshake = "ClientHandshake"
    case connectionAccepted = "ConnectionAccepted"
    case connectionRejected = "ConnectionRejected"
    case aiConversation = "AIConversation"
    case ping = "Ping"
    case pong = "Pong"
    case echo = "Echo"
}

/// 简化的 JSON 值类型 - 现代化精简设计
enum JSONValue: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .number(let number):
            try container.encode(number)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

// MARK: - JSONValue Convenience Extensions

extension JSONValue {
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
}

// MARK: - Unified VisionSync Message

/// 现代化 VisionSync 消息结构 - 智能协议适配
struct VisionMessage: Codable, Sendable {
    let type: MessageType
    let payload: [String: JSONValue]
    let timestamp: UInt64
    let id: String

    // MARK: - 现代化 Streaming 协议 (智能适配)
    let isStreaming: Bool
    let isFinal: Bool
    let streamId: String
    let chunkIndex: Int

    init(
        type: MessageType,
        payload: [String: JSONValue] = [:],
        isStreaming: Bool = false,
        isFinal: Bool = true,
        streamId: String = "",
        chunkIndex: Int = 0
    ) {
        self.type = type
        self.payload = payload
        self.timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        self.id = UUID().uuidString
        self.isStreaming = isStreaming
        self.isFinal = isFinal
        self.streamId = streamId.isEmpty ? UUID().uuidString : streamId
        self.chunkIndex = chunkIndex
    }

    // MARK: - 智能协议适配解码
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 基础字段（必需）
        type = try container.decode(MessageType.self, forKey: .type)
        payload = try container.decode([String: JSONValue].self, forKey: .payload)
        timestamp = try container.decode(UInt64.self, forKey: .timestamp)
        id = try container.decode(String.self, forKey: .id)

        // Streaming 字段（智能适配）
        isStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreaming) ?? false
        isFinal = try container.decodeIfPresent(Bool.self, forKey: .isFinal) ?? true
        streamId = try container.decodeIfPresent(String.self, forKey: .streamId) ?? UUID().uuidString
        chunkIndex = try container.decodeIfPresent(Int.self, forKey: .chunkIndex) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case type, payload, timestamp, id
        case isStreaming, isFinal, streamId, chunkIndex
    }
}

// MARK: - Connection State

/// Roo Code WebSocket 连接状态 - 精简设计
enum RooCodeConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case failed(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .failed(let error): return "Failed: \(error)"
        }
    }

    var displayText: String {
        switch self {
        case .disconnected: return "Offline"
        case .connecting: return "Connecting..."
        case .connected: return "Online"
        case .failed: return "Connection Failed"
        }
    }

    static func == (lhs: RooCodeConnectionState, rhs: RooCodeConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Message Factory Methods

extension VisionMessage {
    /// 创建客户端握手消息
    static func clientHandshake(
        clientType: String = "visionOS",
        version: String = "1.0.0",
        capabilities: [String] = ["ai_conversation", "trigger_send", "echo"]
    ) -> VisionMessage {
        return VisionMessage(type: .clientHandshake, payload: [
            "clientType": .string(clientType),
            "version": .string(version),
            "capabilities": .array(capabilities.map { .string($0) })
        ])
    }

    /// 创建 Ping 消息
    static func ping() -> VisionMessage {
        return VisionMessage(type: .ping)
    }

    /// 创建 Echo 消息
    static func echo(original: [String: JSONValue]) -> VisionMessage {
        return VisionMessage(type: .echo, payload: [
            "original": .object(original),
            "timestamp": .number(Double(Date().timeIntervalSince1970 * 1000))
        ])
    }
}

// MARK: - Legacy Support Types

/// AI 对话消息 - 兼容现有代码
struct AIConversationMessage: Codable, Sendable, Identifiable {
    let id: String
    let sessionId: String
    let role: MessageRole
    let content: String
    let timestamp: UInt64

    init(id: String = UUID().uuidString, sessionId: String, role: MessageRole, content: String, timestamp: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)) {
        self.id = id
        self.sessionId = sessionId
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

/// 消息角色
enum MessageRole: String, Codable, Sendable {
    case user, assistant, system
}

/// 编辑器状态 - 兼容现有代码
struct EditorState: Codable, Sendable {
    let filePath: String?
    let cursorLine: UInt32
    let cursorColumn: UInt32
    let contentPreview: String

    init(filePath: String? = nil, cursorLine: UInt32 = 0, cursorColumn: UInt32 = 0, contentPreview: String = "") {
        self.filePath = filePath
        self.cursorLine = cursorLine
        self.cursorColumn = cursorColumn
        self.contentPreview = contentPreview
    }
}

// MARK: - Service Discovery Types

/// Roo Code 服务信息
struct RooCodeService: Codable, Sendable, Identifiable {
    let id = UUID()
    let name: String
    let websocketURL: URL
    let version: String
    let platform: String
    let app: String
    let capabilities: [String]

    var displayName: String {
        return name
    }

    var webSocketURL: URL? {
        return websocketURL
    }

    private enum CodingKeys: String, CodingKey {
        case name, version, platform, app, capabilities
        case websocketURL = "websocket_url"
    }
}

/// Roo Code 服务发现管理器
@MainActor
@Observable
final class RooCodeDiscoveryService {
    private(set) var discoveredServices: [RooCodeService] = []
    private(set) var isScanning = false
    private(set) var error: String?

    private var scanningTask: Task<Void, Never>?
    private let networkScanner = NetworkScanner()

    func startScanning(preserveServices: Bool = false) {
        guard !isScanning else { return }

        if !preserveServices {
            discoveredServices.removeAll()
        }

        isScanning = true
        error = nil

        scanningTask = Task { @MainActor in
            await performServiceDiscovery()
            isScanning = false
        }
    }

    func stopScanning() {
        scanningTask?.cancel()
        scanningTask = nil
        isScanning = false
    }

    private func performServiceDiscovery() async {
        logger.info("🔍 [DEBUG] Starting Roo Code service discovery process", category: .connection)
        
        // 使用真正的网络扫描
        let services = await networkScanner.scanForServices()
        
                if !Task.isCancelled {
                    logger.info("🔍 [DEBUG] Service discovery completed. Task cancelled: false, Services found: \(services.count)", category: .connection)
                    
                    if services.isEmpty {
                        // 如果没有发现服务，添加本地回退选项
                        let fallbackService = RooCodeService(
                            name: "Roo Code - Local (Fallback)",
                            websocketURL: URL(string: "ws://localhost:8765")!,
                            version: "1.0.0",
                            platform: "macOS",
                            app: "Roo Code",
                            capabilities: ["ai_conversation", "trigger_send", "echo", "ping_pong"]
                        )
                        discoveredServices = [fallbackService]
                        logger.info("🔍 [DEBUG] No services discovered on network, using fallback localhost:8765", category: .connection)
                    } else {
                        // 直接使用发现的服务 - 无需转换
                        discoveredServices = services
                        logger.info("🔍 [DEBUG] Successfully discovered \(services.count) Roo Code services on network", category: .connection)
                        for (index, service) in services.enumerated() {
                            logger.info("🔍 [DEBUG] Service \(index + 1): \(service.name) at \(service.websocketURL)", category: .connection)
                        }
                    }
                    
                    // 服务发现完成后，通知ConnectionManager尝试自动连接
                    logger.info("🔍 [DEBUG] Service discovery notifying ConnectionManager to attempt auto-connection", category: .connection)
                    Task { @MainActor in
                        RooCodeConnectionManager.shared.autoConnectIfNeeded()
                    }
                } else {
                    logger.warning("🔍 [DEBUG] Service discovery task was cancelled", category: .connection)
                }
    }
}
