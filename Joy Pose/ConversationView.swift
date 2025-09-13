//
//  ConversationView.swift
//  Joy Pose
//
//  Roo Code Native Conversation View - Direct Implementation
//

import SwiftUI

/// Direct conversation view - Roo Code pixel-perfect implementation
struct ConversationView: View {
    @Environment(AIConversationManager.self) private var conversationManager

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if conversationManager.visibleMessages.isEmpty {
                        emptyStateView
                    } else {
                        // Direct message rendering - no grouping, no nesting
                        ForEach(conversationManager.visibleMessages, id: \.id) { message in
                            MessageRowView(
                                message: message,
                                onInteraction: handleMessageInteraction
                            )
                            .id(message.id)
                        }
                    }
                }
            }
            .onChange(of: conversationManager.visibleMessages.count) { oldCount, newCount in
                logger.info("Messages changed: \(oldCount) -> \(newCount)", category: .ai)

                // Auto-scroll to latest message
                if newCount > oldCount, let lastMessage = conversationManager.visibleMessages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .onAppear {
            logger.info("Conversation view appeared with \(conversationManager.visibleMessages.count) messages", category: .ai)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No messages yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("Start a conversation with Roo Code")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func handleMessageInteraction(_ interaction: String) {
        logger.info("Message interaction: \(interaction)", category: .ai)
        // Handle message interactions (copy, etc.)
    }
}

