//
//  LanguageMapper.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation

/// Simple language mapping utility for file type detection (Pure SwiftUI version)
struct LanguageMapper {

    /// Check if file is a code file
    static func isCodeFile(_ fileName: String) -> Bool {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        return codeExtensions.contains(fileExtension)
    }

    /// Check if file is an image file
    static func isImageFile(_ fileName: String) -> Bool {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        return imageExtensions.contains(fileExtension)
    }

    /// Get file icon name
    static func fileIcon(for fileName: String, isDirectory: Bool = false) -> String {
        if isDirectory {
            return "folder.fill"
        }

        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        switch fileExtension {
        case "swift": return "swift"
        case "py", "pyw", "pyi": return "doc.text.fill"
        case "js", "jsx", "mjs", "ts", "tsx": return "doc.text.fill"
        case "java", "cpp", "c", "h": return "doc.text.fill"
        case "json", "yaml", "yml": return "doc.badge.gearshape"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        case "zip", "tar", "gz": return "doc.zipper"
        case "md", "markdown": return "doc.richtext"
        case "txt": return "doc.text"
        default: return "doc"
        }
    }

    /// Supported code file extensions
    private static let codeExtensions: Set<String> = [
        // JavaScript family
        "js", "jsx", "mjs", "ts", "tsx",
        // Python
        "py", "pyw", "pyi",
        // Swift
        "swift",
        // Web technologies
        "html", "htm", "css",
        // Data formats
        "json", "yaml", "yml", "md", "markdown",
        // System programming
        "c", "h", "cpp", "cc", "cxx", "hpp", "hxx", "rs", "go", "java",
        // Shell scripts
        "sh", "bash", "zsh"
    ]

    /// Supported image file extensions
    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp", "tiff", "ico"
    ]
    
    /// Get display name for file type
    static func displayName(for filePath: String) -> String {
        let fileExtension = (filePath as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "js", "jsx", "mjs": return "JavaScript"
        case "ts", "tsx": return "TypeScript"
        case "py", "pyw", "pyi": return "Python"
        case "swift": return "Swift"
        case "html", "htm": return "HTML"
        case "css": return "CSS"
        case "json": return "JSON"
        case "yaml", "yml": return "YAML"
        case "md", "markdown": return "Markdown"
        case "c", "h": return "C"
        case "cpp", "cc", "cxx", "hpp", "hxx": return "C++"
        case "rs": return "Rust"
        case "go": return "Go"
        case "java": return "Java"
        case "sh", "bash", "zsh": return "Shell"
        default: return "Text"
        }
    }
}
