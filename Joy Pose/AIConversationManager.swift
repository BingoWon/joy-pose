//
//  AIConversationManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import Combine
import SwiftUI

/// 纯对话管理器 - 专注于任务和对话，不处理连接 - 单例模式防止重复订阅
@MainActor
@Observable
final class AIConversationManager {
    // MARK: - Singleton
    static let shared = AIConversationManager()

    // Core State
    private(set) var messages: [AIConversationMessage] = []
    private(set) var isSending = false
    private(set) var lastError: String?

    /// 可见消息 - 直接用于 UI 显示
    var visibleMessages: [ClineMessage] {
        return messageManager.visibleMessages
    }

    // Task Management
    private(set) var currentTask: TaskInfo?
    private(set) var taskStatus: TaskStatus = .idle
    private(set) var taskMetrics = TaskMetrics()

    // Session Management
    private let sessionId = "current-session"
    private var cancellables = Set<AnyCancellable>()

    // Roo Code 连接管理器引用 - 只读访问
    private var rooCodeConnectionManager: RooCodeConnectionManager { RooCodeConnectionManager.shared }

    // 现代化消息管理器 - 专注版本去重
    let messageManager = MessageManager()

    // Task Status Enumeration
    enum TaskStatus {
        case idle
        case creating
        case active
        case paused
        case completed
    }

    private init() {
        setupMessageHandling()
        logger.info("AIConversationManager initialized", category: .ai)
    }

    /// Setup message handling - Pure @Observable pattern
    private func setupMessageHandling() {
        // 订阅来自 WebSocket 的消息
        rooCodeConnectionManager.webSocketClient.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Connection State

    var isConnected: Bool {
        rooCodeConnectionManager.isConnected
    }

    var connectionState: RooCodeConnectionState {
        rooCodeConnectionManager.connectionState
    }

    // MARK: - Message Sending

    /// 发送用户消息 - 现代化精简设计
    func sendMessage(_ content: String) async {
        logger.info("sendMessage called with content: \(content.prefix(100))", category: .ai)

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Empty content, skipping send", category: .ai)
            return
        }
        guard isConnected else {
            lastError = "Not connected to Roo Code"
            logger.error("Not connected to Roo Code", category: .ai)
            return
        }

        do {
            // 创建用户消息并添加到会话
            let userMessage = AIConversationMessage(
                id: UUID().uuidString,
                sessionId: sessionId,
                role: .user,
                content: content,
                timestamp: UInt64(Date().timeIntervalSince1970 * 1000)
            )
            logger.debug("Created user message with ID: \(userMessage.id)", category: .ai)

            messages.append(userMessage)
            isSending = true
            lastError = nil
            logger.debug("Added message to list - Total: \(messages.count)", category: .ai)

            logger.info("Sending user message - ID: \(userMessage.id)", category: .ai)
            logger.info("Content: \(content)", category: .ai)

            // 更新任务状态
            if currentTask == nil {
                taskStatus = .creating
                logger.debug("Updated task status to creating", category: .ai)
            }

            // 使用现代化消息工厂发送
            let message = MessageFactory.completeMessage(sessionId: sessionId, role: .user, content: content)
            logger.debug("Created VisionMessage for sending", category: .ai)

            await rooCodeConnectionManager.webSocketClient.sendMessage(message)
            logger.info("Message sent successfully - Total messages: \(messages.count)", category: .ai)

            // 添加到消息管理器
            messageManager.addUserMessage(content)

        } catch {
            lastError = "Failed to send message: \(error.localizedDescription)"
            logger.error("Failed to send message: \(error.localizedDescription)", category: .ai)
        }

        isSending = false
    }

    /// 处理来自 WebSocket 的消息
    private func handleIncomingMessage(_ message: VisionMessage) {
        logger.info("Received message type: \(message.type.rawValue)", category: .ai)

        switch message.type {
        case .aiConversation:
            // 转发给消息管理器处理
            messageManager.processMessage(message)
            
            // 更新本地消息列表
            if let aiMessage = convertToAIConversationMessage(message) {
                messages.append(aiMessage)
                logger.debug("Added AI message to conversation", category: .ai)
            }
            
        case .connectionAccepted:
            logger.info("Connection accepted", category: .ai)
            
        default:
            logger.debug("Unhandled message type: \(message.type.rawValue)", category: .ai)
        }
    }

    /// 将 VisionMessage 转换为 AIConversationMessage
    private func convertToAIConversationMessage(_ message: VisionMessage) -> AIConversationMessage? {
        guard message.type == .aiConversation,
              let content = message.payload["content"]?.stringValue,
              let role = message.payload["role"]?.stringValue else {
            return nil
        }
        
        let messageRole = MessageRole(rawValue: role) ?? .assistant
        
        return AIConversationMessage(
            id: message.id,
            sessionId: sessionId,
            role: messageRole,
            content: content,
            timestamp: message.timestamp
        )
    }

    // MARK: - Task Management

    /// 创建新任务
    func createTask(description: String) {
        let task = TaskInfo(
            id: UUID().uuidString,
            description: description,
            status: .active,
            createdAt: Date()
        )
        
        currentTask = task
        taskStatus = .active
        taskMetrics.reset()
        
        logger.info("Created new task: \(description)", category: .ai)
    }

    /// 完成当前任务
    func completeTask() {
        guard let task = currentTask else { return }
        
        currentTask?.status = .completed
        taskStatus = .completed
        
        logger.info("Completed task: \(task.description)", category: .ai)
    }

    /// 清除当前任务
    func clearTask() {
        currentTask = nil
        taskStatus = .idle
        taskMetrics.reset()
        
        logger.info("Cleared current task", category: .ai)
    }

    // MARK: - Message Management

    /// 清除所有消息
    func clearMessages() {
        messages.removeAll()
        messageManager.clearMessages()
        lastError = nil
        
        logger.info("Cleared all messages", category: .ai)
    }

    /// 重试最后一条消息
    func retryLastMessage() async {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
            logger.warning("No user message to retry", category: .ai)
            return
        }
        
        await sendMessage(lastUserMessage.content)
    }
}

// MARK: - Supporting Data Models

/// 任务信息
struct TaskInfo: Identifiable, Codable {
    let id: String
    let description: String
    var status: TaskStatus
    let createdAt: Date
    
    enum TaskStatus: String, Codable {
        case active = "active"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
    }
}

/// 任务指标
struct TaskMetrics {
    var messagesExchanged: Int = 0
    var tokensUsed: Int = 0
    var duration: TimeInterval = 0
    var startTime: Date?
    
    mutating func reset() {
        messagesExchanged = 0
        tokensUsed = 0
        duration = 0
        startTime = Date()
    }
    
    mutating func incrementMessages() {
        messagesExchanged += 1
    }
    
    mutating func addTokens(_ count: Int) {
        tokensUsed += count
    }
    
    mutating func updateDuration() {
        guard let startTime = startTime else { return }
        duration = Date().timeIntervalSince(startTime)
    }
}

