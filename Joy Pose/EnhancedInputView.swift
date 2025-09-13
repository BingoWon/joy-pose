//
//  EnhancedInputView.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

/// Enhanced input view - Equivalent to Roo Code's ChatTextArea with advanced features (excluding speech recognition)
struct EnhancedInputView: View {
    @Binding var text: String
    @State private var inputManager = EnhancedInputManager()
    @State private var selectedMode: AIMode = .chat
    @State private var selectedImages: [String] = []
    @State private var showingImagePicker = false
    @State private var showingModeSelector = false
    @FocusState private var isTextFieldFocused: Bool
    
    let onSend: () -> Void
    let isEnabled: Bool
    let isSending: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Mentions Popover
            if inputManager.showingMentions {
                mentionsPopover
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Commands Popover
            if inputManager.showingCommands {
                commandsPopover
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            VStack(spacing: 12) {
                // Mode and Tools Row
                selectorRow
                
                // Main Input Area
                inputArea
                
                // Attachment Preview
                if !selectedImages.isEmpty {
                    attachmentPreview
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .animation(.easeInOut(duration: 0.2), value: inputManager.showingMentions)
        .animation(.easeInOut(duration: 0.2), value: inputManager.showingCommands)
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showingModeSelector) {
            ModeSelectorView(selectedMode: $selectedMode)
        }
        .onChange(of: text) { _, newValue in
            inputManager.text = newValue
        }
        .onAppear {
            // 自动聚焦到文本输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var mentionsPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "at")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Files")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Close") {
                    inputManager.hideMentions()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(inputManager.filteredMentions, id: \.self) { mention in
                        mentionRow(mention)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var commandsPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "command")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.purple)
                
                Text("Commands")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Close") {
                    inputManager.hideCommands()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(inputManager.filteredCommands, id: \.command) { command in
                        commandRow(command)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var selectorRow: some View {
        HStack {
            // AI Mode Selector
            Button(action: { showingModeSelector = true }) {
                HStack(spacing: 6) {
                    Image(systemName: selectedMode.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedMode.color)
                    
                    Text(selectedMode.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Tools Row
            HStack(spacing: 8) {
                // Image Attachment
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedImages.isEmpty ? .secondary : .blue)
                }
                .buttonStyle(.plain)
                
                // File Attachment
                Button(action: { /* TODO: File picker */ }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text Input
            TextField("Ask Roo Code anything...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .lineLimit(1...6)
                .focused($isTextFieldFocused)
                .disabled(!isEnabled || isSending)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
                .onTapGesture {
                    isTextFieldFocused = true
                }
            
            // Send Button
            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                    }
                }
                .foregroundColor(canSend ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var attachmentPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedImages, id: \.self) { imageName in
                    attachmentCard(imageName)
                }
            }
            .padding(.horizontal, 12)
        }
    }
    
    private func mentionRow(_ mention: String) -> some View {
        Button(action: {
            inputManager.selectMention(mention)
            text = inputManager.text
        }) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(mention)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.clear)
        .onHover { isHovered in
            // TODO: Add hover effect
        }
    }
    
    private func commandRow(_ command: AICommand) -> some View {
        Button(action: {
            inputManager.selectCommand(command)
            text = inputManager.text
        }) {
            HStack {
                Image(systemName: command.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(command.command)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(command.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.clear)
    }
    
    private func attachmentCard(_ imageName: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
            
            Text(imageName)
                .font(.caption)
                .foregroundColor(.primary)
            
            Button(action: {
                selectedImages.removeAll { $0 == imageName }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
    
    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Supporting Types

/// AI Mode enumeration
enum AIMode: String, CaseIterable {
    case chat = "chat"
    case architect = "architect"
    case editor = "editor"
    case ask = "ask"
    
    var displayName: String {
        switch self {
        case .chat: return "Chat"
        case .architect: return "Architect"
        case .editor: return "Editor"
        case .ask: return "Ask"
        }
    }
    
    var icon: String {
        switch self {
        case .chat: return "message.circle"
        case .architect: return "building.2"
        case .editor: return "pencil.circle"
        case .ask: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .chat: return .blue
        case .architect: return .purple
        case .editor: return .green
        case .ask: return .orange
        }
    }
}

/// AI Command structure
struct AICommand {
    let command: String
    let description: String
    let icon: String
}

/// Enhanced Input Manager
@Observable
class EnhancedInputManager {
    var text: String = ""
    var showingMentions = false
    var showingCommands = false
    var filteredMentions: [String] = []
    var filteredCommands: [AICommand] = []
    
    private let availableMentions = [
        "package.json",
        "README.md",
        "src/main.ts",
        "src/components/",
        "docs/"
    ]
    
    private let availableCommands = [
        AICommand(command: "/fix", description: "Fix code issues", icon: "wrench"),
        AICommand(command: "/explain", description: "Explain code", icon: "questionmark.circle"),
        AICommand(command: "/optimize", description: "Optimize performance", icon: "speedometer"),
        AICommand(command: "/test", description: "Write tests", icon: "checkmark.circle"),
        AICommand(command: "/refactor", description: "Refactor code", icon: "arrow.triangle.2.circlepath")
    ]
    
    func selectMention(_ mention: String) {
        // Replace @mention in text
        text = text.replacingOccurrences(of: "@\(mention)", with: "@\(mention) ")
        hideMentions()
    }
    
    func selectCommand(_ command: AICommand) {
        // Replace /command in text
        text = text.replacingOccurrences(of: command.command, with: "\(command.command) ")
        hideCommands()
    }
    
    func hideMentions() {
        showingMentions = false
        filteredMentions = []
    }
    
    func hideCommands() {
        showingCommands = false
        filteredCommands = []
    }
}

// MARK: - Placeholder Views

struct ImagePickerView: View {
    @Binding var selectedImages: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Image Picker")
                .font(.title2)
                .padding()
            
            Text("Image picker functionality would be implemented here")
                .foregroundColor(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
    }
}

struct ModeSelectorView: View {
    @Binding var selectedMode: AIMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select AI Mode")
                .font(.title2)
                .padding()
            
            ForEach(AIMode.allCases, id: \.self) { mode in
                Button(action: {
                    selectedMode = mode
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: mode.icon)
                            .foregroundColor(mode.color)
                        
                        VStack(alignment: .leading) {
                            Text(mode.displayName)
                                .fontWeight(.medium)
                            Text("Mode description here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}

