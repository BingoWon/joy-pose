//
//  MessageFactory.swift
//  Joy Pose
//
//  消息工厂类 - 创建标准化的VisionSync消息
//

import Foundation

/// 消息工厂类 - 负责创建各种类型的 VisionSync 消息
struct MessageFactory {
    
    // MARK: - AI 对话消息创建
    
    /// 创建完整的AI对话消息
    static func completeMessage(
        sessionId: String,
        role: MessageRole,
        content: String,
        messageId: String? = nil
    ) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(role.rawValue),
            "content": .string(content),
            "messageId": .string(messageId ?? UUID().uuidString),
            "type": .string("say:text"),
            "text": .string(content),
            "partial": .bool(false)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload
        )
    }
    
    /// 创建流式AI对话消息（部分消息）
    static func streamingMessage(
        sessionId: String,
        role: MessageRole,
        content: String,
        messageId: String,
        isStreaming: Bool = true,
        isFinal: Bool = false,
        chunkIndex: Int = 0
    ) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(role.rawValue),
            "content": .string(content),
            "messageId": .string(messageId),
            "type": .string("say:text"),
            "text": .string(content),
            "partial": .bool(!isFinal)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload,
            isStreaming: isStreaming,
            isFinal: isFinal,
            streamId: messageId,
            chunkIndex: chunkIndex
        )
    }
    
    // MARK: - 用户消息创建
    
    /// 创建用户消息
    static func userMessage(
        sessionId: String,
        content: String,
        messageId: String? = nil
    ) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(MessageRole.user.rawValue),
            "content": .string(content),
            "messageId": .string(messageId ?? UUID().uuidString),
            "type": .string("ask:followup"),
            "text": .string(content),
            "partial": .bool(false)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload
        )
    }
    
    // MARK: - 系统消息创建
    
    /// 创建系统消息
    static func systemMessage(
        sessionId: String,
        content: String,
        messageType: String = "say:text"
    ) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(MessageRole.system.rawValue),
            "content": .string(content),
            "messageId": .string(UUID().uuidString),
            "type": .string(messageType),
            "text": .string(content),
            "partial": .bool(false)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload
        )
    }
    
    // MARK: - 错误消息创建
    
    /// 创建错误消息
    static func errorMessage(
        sessionId: String,
        error: String,
        messageId: String? = nil
    ) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(MessageRole.assistant.rawValue),
            "content": .string(error),
            "messageId": .string(messageId ?? UUID().uuidString),
            "type": .string("say:error"),
            "text": .string(error),
            "partial": .bool(false)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload
        )
    }
    
    // MARK: - 任务相关消息
    
    /// 创建任务开始消息
    static func taskStartedMessage(
        sessionId: String,
        taskDescription: String
    ) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(MessageRole.assistant.rawValue),
            "content": .string("Task started: \(taskDescription)"),
            "messageId": .string(UUID().uuidString),
            "type": .string("say:taskStarted"),
            "text": .string("Task started: \(taskDescription)"),
            "partial": .bool(false)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload
        )
    }
    
    /// 创建任务完成消息
    static func taskCompletedMessage(
        sessionId: String,
        result: String
    ) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(MessageRole.assistant.rawValue),
            "content": .string(result),
            "messageId": .string(UUID().uuidString),
            "type": .string("say:completionResult"),
            "text": .string(result),
            "partial": .bool(false)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload
        )
    }
}

// MARK: - 便利扩展

extension MessageFactory {
    /// 从 AIConversationMessage 创建 VisionMessage
    static func fromAIConversationMessage(_ message: AIConversationMessage) -> VisionMessage {
        return completeMessage(
            sessionId: message.sessionId,
            role: message.role,
            content: message.content,
            messageId: message.id
        )
    }
    
    /// 从 ClineMessage 创建 VisionMessage
    static func fromClineMessage(_ message: ClineMessage, sessionId: String) -> VisionMessage {
        let payload: [String: JSONValue] = [
            "sessionId": .string(sessionId),
            "role": .string(message.role.rawValue),
            "content": .string(message.text),
            "messageId": .string(message.messageId ?? message.id),
            "type": .string(message.type.rawValue),
            "text": .string(message.text),
            "partial": .bool(message.partial ?? false)
        ]
        
        return VisionMessage(
            type: .aiConversation,
            payload: payload
        )
    }
}
