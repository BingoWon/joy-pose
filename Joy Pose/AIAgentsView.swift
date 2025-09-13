//
//  AIAgentsView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct AIAgentsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var messageText = ""
    @State private var messages: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Agents")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Ready to assist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Clear") {
                    messages.removeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.regularMaterial)

            // Messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if messages.isEmpty {
                        VStack(spacing: 32) {
                            Spacer()

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(.blue)

                            VStack(spacing: 8) {
                                Text("AI Assistant")
                                    .font(.title)
                                    .fontWeight(.bold)

                                Text("Ready to help with your development tasks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }

            // Input
            HStack {
                TextField("Ask AI assistant...", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
    }

    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        messages.append("You: \(message)")
        messages.append("AI: I'm a placeholder AI assistant. Your message was: \(message)")
        
        messageText = ""
    }
}

