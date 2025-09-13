import SwiftUI
import UIKit
import Runestone

/// Modern Runestone text editor wrapper for visionOS with syntax highlighting and line numbers
struct RunestoneTextView: UIViewRepresentable {
    @Binding var text: String
    let filePath: String?
    let isEditable: Bool
    let font: UIFont
    
    init(
        text: Binding<String>,
        filePath: String? = nil,
        isEditable: Bool = true,
        font: UIFont = .monospacedSystemFont(ofSize: 15, weight: .regular)
    ) {
        self._text = text
        self.filePath = filePath
        self.isEditable = isEditable
        self.font = font
    }
    
    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        textView.editorDelegate = context.coordinator
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.backgroundColor = UIColor.systemBackground
        textView.contentInsetAdjustmentBehavior = .never

        // Enable professional code editor features
        textView.showLineNumbers = true
        textView.isLineWrappingEnabled = false
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no

        // Configure content insets for optimal spacing
        textView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 12)

        // Configure text view state with theme and language detection
        let theme = DefaultTheme()

        // Use LanguageMapper for automatic language detection and syntax highlighting
        if let filePath = filePath,
           let languageMode = LanguageMapper.languageMode(for: filePath) {
            let state = TextViewState(
                text: text,
                theme: theme,
                language: languageMode.language
            )
            textView.setState(state)
        } else {
            let state = TextViewState(
                text: text,
                theme: theme
            )
            textView.setState(state)
        }

        return textView
    }
    
    func updateUIView(_ uiView: TextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        
        if uiView.isEditable != isEditable {
            uiView.isEditable = isEditable
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, TextViewDelegate {
        let parent: RunestoneTextView
        
        init(_ parent: RunestoneTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: TextView) {
            parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: TextView) {
            // Handle selection changes if needed
        }
        
        func textView(_ textView: TextView, canReplaceTextIn range: NSRange) -> Bool {
            return parent.isEditable
        }
    }
}

#Preview {
    RunestoneTextView(
        text: .constant("""
        import SwiftUI

        struct ContentView: View {
            @State private var message = "Hello, World!"

            var body: some View {
                VStack {
                    Text(message)
                        .font(.title)
                        .padding()

                    Button("Tap me!") {
                        message = "Button tapped!"
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        """),
        filePath: "ContentView.swift",
        isEditable: true,
        font: .monospacedSystemFont(ofSize: 14, weight: .regular)
    )
    .frame(width: 600, height: 400)
}
