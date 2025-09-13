//
//  MessageRowView.swift
//  Joy Pose
//
//  Roo Code Native Message Rendering - Direct Implementation
//

import SwiftUI

/// Direct message row rendering - Roo Code pixel-perfect implementation
struct MessageRowView: View {
    let message: ClineMessage
    let onInteraction: ((String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Direct content rendering based on message type - Roo Code style
            messageContent
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .onAppear {
            logger.debug("Rendering message: \(message.type.rawValue)", category: .ai)
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.type {
        case .say:
            sayMessageContent
        case .ask:
            askMessageContent
        }
    }
    
    // MARK: - Say Message Types
    
    @ViewBuilder
    private var sayMessageContent: some View {
        switch message.type {
        case .say(let say):
            switch say {
            case .text:
                textMessage
            case .completionResult:
                completionResult
            case .error:
                errorMessage
            case .reasoning:
                reasoningMessage
            case .userFeedback:
                userFeedbackMessage
            case .commandOutput:
                commandOutputMessage
            case .image:
                imageMessage
            default:
                defaultSayMessage
            }
        default:
            EmptyView()
        }
    }
    
    // MARK: - Ask Message Types
    
    @ViewBuilder
    private var askMessageContent: some View {
        switch message.type {
        case .ask(let ask):
            switch ask {
            case .followup:
                followupMessage
            case .command:
                commandMessage
            case .tool:
                toolMessage
            case .completionResult:
                completionConfirmation
            default:
                defaultAskMessage
            }
        default:
            EmptyView()
        }
    }
    
    // MARK: - Text Message (Most Common)
    
    private var textMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Message header with role indicator
            HStack {
                Image(systemName: roleIcon)
                    .foregroundColor(roleColor)
                    .font(.caption)
                
                Text(roleDisplayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if message.isPartial {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Typing...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Message content
            Text(message.displayText)
                .font(.body)
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Specialized Message Types
    
    private var completionResult: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Task Completed")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(message.displayText)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var errorMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Error")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            
            Text(message.displayText)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var reasoningMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("Reasoning")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            Text(message.displayText)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var userFeedbackMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.orange)
                Text("User Feedback")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
            
            Text(message.displayText)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var commandOutputMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(.green)
                Text("Command Output")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            Text(message.displayText)
                .font(.system(.body, design: .monospaced))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
                .foregroundColor(.green)
        }
    }
    
    private var imageMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.purple)
                Text("Image")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
            
            Text("Image content: \(message.displayText)")
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var followupMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text("You")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Text(message.displayText)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var commandMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.orange)
                Text("Command Request")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
            
            Text(message.displayText)
                .font(.system(.body, design: .monospaced))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var toolMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundColor(.indigo)
                Text("Tool Usage")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.indigo)
            }
            
            Text(message.displayText)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var completionConfirmation: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                Text("Completion Confirmation")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            Text(message.displayText)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var defaultSayMessage: some View {
        textMessage
    }
    
    private var defaultAskMessage: some View {
        textMessage
    }
    
    // MARK: - Helper Properties
    
    private var roleIcon: String {
        switch message.role {
        case .user:
            return "person.circle.fill"
        case .assistant:
            return "brain.head.profile"
        case .system:
            return "gear.circle.fill"
        }
    }
    
    private var roleColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return .green
        case .system:
            return .gray
        }
    }
    
    private var roleDisplayName: String {
        switch message.role {
        case .user:
            return "You"
        case .assistant:
            return "Roo Code"
        case .system:
            return "System"
        }
    }
}

