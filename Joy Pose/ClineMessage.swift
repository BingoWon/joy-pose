//
//  ClineMessage.swift
//  Joy Pose
//
//  Roo Code 消息模型 - 完整孪生实现
//

import Foundation

// MARK: - ClineAsk 类型定义

/// 询问类型 - 需要用户交互的消息
enum ClineAsk: String, Codable, CaseIterable {
    // 交互式询问
    case followup = "followup"
    case command = "command"
    case commandOutput = "command_output"
    case tool = "tool"
    case browserActionLaunch = "browser_action_launch"
    case useMcpServer = "use_mcp_server"

    // 空闲状态询问
    case completionResult = "completion_result"
    case apiReqFailed = "api_req_failed"
    case resumeCompletedTask = "resume_completed_task"
    case mistakeLimitReached = "mistake_limit_reached"
    case autoApprovalMaxReqReached = "auto_approval_max_req_reached"

    // 可恢复询问
    case resumeTask = "resume_task"

    // 批量操作询问
    case filePermission = "file_permission"
    case diffApproval = "diff_approval"
}

// MARK: - ClineSay 类型定义

/// 说话类型 - AI 输出的消息
enum ClineSay: String, Codable, CaseIterable {
    // 用户可见消息
    case text = "text"
    case completionResult = "completion_result"
    case error = "error"
    case commandOutput = "command_output"
    case userFeedback = "user_feedback"
    case reasoning = "reasoning"
    case image = "image"

    // 技术状态消息（通常过滤）
    case apiReqStarted = "api_req_started"
    case apiReqFinished = "api_req_finished"
    case taskCompleted = "task_completed"
    case taskError = "task_error"
    case taskStarted = "task_started"
    case toolsUsed = "tools_used"
    case webSearchStarted = "web_search_started"
    case webSearchFinished = "web_search_finished"
    case commandStarted = "command_started"
    case commandFinished = "command_finished"
    case fileReadStarted = "file_read_started"
    case fileReadFinished = "file_read_finished"
    case fileWriteStarted = "file_write_started"
    case fileWriteFinished = "file_write_finished"
}

// MARK: - ClineMessage 核心模型

/// Roo Code 消息模型 - 完整孪生实现
struct ClineMessage: Codable, Identifiable, Sendable {
    let id: String
    var type: ClineMessageType
    var text: String
    var partial: Bool?
    var messageId: String?

    // 时间戳
    let timestamp: UInt64

    init(
        id: String = UUID().uuidString,
        type: ClineMessageType,
        text: String,
        partial: Bool? = nil,
        messageId: String? = nil,
        timestamp: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.partial = partial
        self.messageId = messageId
        self.timestamp = timestamp
    }
}

// MARK: - ClineMessageType 枚举

/// Roo Code 消息类型
enum ClineMessageType: Codable, Sendable {
    case ask(ClineAsk)
    case say(ClineSay)

    var rawValue: String {
        switch self {
        case .ask(let ask):
            return "ask:\(ask.rawValue)"
        case .say(let say):
            return "say:\(say.rawValue)"
        }
    }

    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        
        switch type {
        case "ask":
            if let ask = ClineAsk(rawValue: value) {
                self = .ask(ask)
            } else {
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid ask type: \(value)")
            }
        case "say":
            if let say = ClineSay(rawValue: value) {
                self = .say(say)
            } else {
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid say type: \(value)")
            }
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid message type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .ask(let ask):
            try container.encode("ask", forKey: .type)
            try container.encode(ask.rawValue, forKey: .value)
        case .say(let say):
            try container.encode("say", forKey: .type)
            try container.encode(say.rawValue, forKey: .value)
        }
    }
}

// MARK: - Message Helpers

extension ClineMessage {
    /// 是否为用户可见消息
    var isVisible: Bool {
        switch type {
        case .ask:
            return true
        case .say(let say):
            switch say {
            case .text, .completionResult, .error, .commandOutput, .userFeedback, .reasoning, .image:
                return true
            default:
                return false
            }
        }
    }
    
    /// 是否为部分消息
    var isPartial: Bool {
        return partial == true
    }
    
    /// 消息的显示文本
    var displayText: String {
        return text
    }
    
    /// 消息角色（用于UI显示）
    var role: MessageRole {
        switch type {
        case .ask:
            return .user
        case .say:
            return .assistant
        }
    }
}


