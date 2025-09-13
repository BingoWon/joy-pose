//
//  AIAgentsView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

/// Main AI Agents interface - Equivalent to Roo Code's ChatView with full feature parity
struct AIAgentsView: View {
    @Environment(AppModel.self) private var appModel
    private var conversationManager: AIConversationManager { AIConversationManager.shared }
    @State private var messageText = ""
    @State private var isCreatingNewTask = false

    var body: some View {
        VStack(spacing: 0) {
            // Streamlined Header
            headerView

            // Error Display
            if let error = conversationManager.lastError {
                errorBanner(error)
            }

            // Direct conversation view - no complex grouping
            ConversationView()
                .environment(conversationManager)

            // Enhanced Input System (Replaces both SmartInputView and TaskCreationView)
            EnhancedInputView(
                text: $messageText,
                onSend: sendMessage,
                isEnabled: conversationManager.isConnected,
                isSending: conversationManager.isSending
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(.regularMaterial)
        .onAppear {
            logger.info("Modern AI Agents view appeared", category: .ai)
        }
    }

    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Agents")
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 8) {
                    connectionStatusIndicator
                    
                    Text(conversationManager.isConnected ? "Connected to Roo Code" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(conversationManager.isConnected ? .green : .secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // Clear Messages Button
                Button("Clear") {
                    conversationManager.clearMessages()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Connection Status Button
                Button(action: {
                    if conversationManager.isConnected {
                        RooCodeConnectionManager.shared.disconnect()
                    } else {
                        RooCodeConnectionManager.shared.startScanning()
                    }
                }) {
                    Image(systemName: conversationManager.isConnected ? "wifi.slash" : "wifi")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
    
    private var connectionStatusIndicator: some View {
        Circle()
            .fill(conversationManager.isConnected ? .green : .red)
            .frame(width: 8, height: 8)
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Dismiss") {
                // Clear error - this would be implemented in the conversation manager
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1))
    }

    // MARK: - Message Sending
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        Task {
            await conversationManager.sendMessage(message)
            messageText = ""
        }
    }
}

