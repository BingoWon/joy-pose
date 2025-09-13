//
//  MessageManager.swift
//  Joy Pose
//
//  Roo Code流式消息管理器 - 完整复刻原生机制
//

import Foundation
import Combine

/// Roo Code流式消息管理器 - 完整复刻原生机制
@MainActor
@Observable
final class MessageManager {
    // MARK: - 依赖注入
    private let messageFilter = MessageFilter()

    // MARK: - 发布器
    /// ClineMessage 发布器 - 发布过滤后的消息
    private let messageSubject = PassthroughSubject<ClineMessage, Never>()

    /// 可见消息发布器 - 发布过滤后的消息
    private let visibleMessageSubject = PassthroughSubject<[ClineMessage], Never>()

    // MARK: - 公开发布器
    var messagePublisher: AnyPublisher<ClineMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    var visibleMessagePublisher: AnyPublisher<[ClineMessage], Never> {
        visibleMessageSubject.eraseToAnyPublisher()
    }

    // MARK: - 状态管理
    /// 所有接收到的消息（包括隐藏的）
    private(set) var allMessages: [ClineMessage] = []

    /// 经过过滤的可见消息 - 直接显示，无分组
    private(set) var visibleMessages: [ClineMessage] = []

    init() {
        logger.info("MessageManager initialized with Roo Code streaming logic", category: .ai)
    }
    
    // MARK: - 消息处理

    /// 处理传入的 VisionMessage，转换为 ClineMessage 并应用流式更新
    func processMessage(_ message: VisionMessage) {
        logger.info("Processing VisionMessage - Type: \(message.type.rawValue)", category: .ai)

        // 转换为 ClineMessage
        guard let clineMessage = convertToClineMessage(message) else {
            logger.warning("Failed to convert VisionMessage to ClineMessage", category: .ai)
            return
        }

        // Roo Code流式更新处理
        addMessageWithStreamingUpdate(clineMessage)
    }

    /// 直接处理 ClineMessage
    func processMessage(_ message: ClineMessage) {
        logger.info("Processing ClineMessage - Type: \(message.type.rawValue)", category: .ai)
        addMessageWithStreamingUpdate(message)
    }
    
    // MARK: - Roo Code流式更新核心逻辑

    /// Roo Code流式添加消息 - 完整复刻原生机制
    private func addMessageWithStreamingUpdate(_ message: ClineMessage) {
        logger.info("Adding message with streaming update - Type: \(message.type.rawValue), Partial: \(message.partial ?? false)", category: .ai)

        // 提取messageId用于流式更新识别
        let messageId = extractMessageId(from: message)

        // 查找具有相同messageId的现有partial消息
        let existingMessageIndex = allMessages.lastIndex { existingMessage in
            existingMessage.partial == true && extractMessageId(from: existingMessage) == messageId
        }

        if message.partial == true {
            if let index = existingMessageIndex {
                // 流式更新现有partial消息
                logger.info("Streaming update to existing partial message with messageId: \(messageId)", category: .ai)
                allMessages[index].text = message.text
                allMessages[index].partial = message.partial
            } else {
                // 新的partial消息
                logger.info("Adding new partial message with messageId: \(messageId)", category: .ai)
                allMessages.append(message)
            }
        } else {
            if let index = existingMessageIndex {
                // 完成partial消息
                logger.info("Completing partial message with messageId: \(messageId)", category: .ai)
                allMessages[index].text = message.text
                allMessages[index].partial = false
            } else {
                // 新的完整消息
                logger.info("Adding new complete message with messageId: \(messageId)", category: .ai)
                allMessages.append(message)
            }
        }

        // 更新可见消息并发布
        updateVisibleMessages()
        
        // 发布单个消息更新
        messageSubject.send(message)
    }

    // MARK: - 消息过滤和更新

    /// 更新可见消息列表
    private func updateVisibleMessages() {
        // 应用过滤器获取可见消息
        let filtered = messageFilter.filterMessages(allMessages)
        visibleMessages = filtered
        
        // 发布可见消息更新
        visibleMessageSubject.send(visibleMessages)
        
        logger.debug("Updated visible messages count: \(visibleMessages.count)", category: .ai)
    }

    // MARK: - 辅助方法

    /// 从消息中提取messageId
    private func extractMessageId(from message: ClineMessage) -> String {
        return message.messageId ?? message.id
    }

    /// 将 VisionMessage 转换为 ClineMessage
    private func convertToClineMessage(_ visionMessage: VisionMessage) -> ClineMessage? {
        guard visionMessage.type == .aiConversation else { return nil }
        
        // 从 payload 中提取消息信息 - 修复为正确的Roo Code格式
        guard let role = visionMessage.payload["role"]?.stringValue,
              let content = visionMessage.payload["content"]?.stringValue else {
            logger.warning("Missing role or content in message payload", category: .ai)
            return nil
        }
        
        // 提取metadata信息
        let metadata = visionMessage.payload["metadata"]?.objectValue
        let originalType = metadata?["originalType"]?.stringValue
        let sayType = metadata?["sayType"]?.stringValue
        let askType = metadata?["askType"]?.stringValue
        let partial = visionMessage.payload["partial"]?.boolValue
        let messageId = metadata?["messageId"]?.stringValue
        
        // 根据role和metadata确定消息类型
        let messageType = determineMessageType(
            role: role,
            originalType: originalType,
            sayType: sayType,
            askType: askType
        )
        
        return ClineMessage(
            id: visionMessage.id,
            type: messageType,
            text: content,
            partial: partial,
            messageId: messageId,
            timestamp: visionMessage.timestamp
        )
    }
    
    /// 根据role和metadata确定消息类型
    private func determineMessageType(
        role: String,
        originalType: String?,
        sayType: String?,
        askType: String?
    ) -> ClineMessageType {
        // 根据originalType确定主要类型
        if let originalType = originalType {
            if originalType == "ask", let askType = askType {
                if let ask = ClineAsk(rawValue: askType) {
                    return .ask(ask)
                }
            } else if originalType == "say", let sayType = sayType {
                if let say = ClineSay(rawValue: sayType) {
                    return .say(say)
                }
            }
        }
        
        // 根据role作为fallback
        if role == "user" {
            return .ask(.followup)
        } else {
            return .say(.text)
        }
    }

    // MARK: - 公开接口

    /// 清除所有消息
    func clearMessages() {
        allMessages.removeAll()
        visibleMessages.removeAll()
        visibleMessageSubject.send(visibleMessages)
        logger.info("Cleared all messages", category: .ai)
    }

    /// 添加用户消息
    func addUserMessage(_ text: String) {
        let userMessage = ClineMessage(
            type: .ask(.followup),
            text: text
        )
        addMessageWithStreamingUpdate(userMessage)
    }
}

// MARK: - MessageFilter

/// 消息过滤器 - 决定哪些消息对用户可见
final class MessageFilter {
    /// 过滤消息，返回用户可见的消息
    func filterMessages(_ messages: [ClineMessage]) -> [ClineMessage] {
        return messages.filter { message in
            // 只显示可见的消息
            message.isVisible
        }
    }
}
