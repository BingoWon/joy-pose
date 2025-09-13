//
//  LanguageMapper.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import Runestone
import TreeSitterJavaScriptRunestone
import TreeSitterPythonRunestone
import TreeSitterSwiftRunestone
import TreeSitterJSONRunestone
import TreeSitterHTMLRunestone
import TreeSitterCSSRunestone
import TreeSitterYAMLRunestone
import TreeSitterMarkdownRunestone
import TreeSitterBashRunestone
import TreeSitterCRunestone
import TreeSitterCPPRunestone
import TreeSitterGoRunestone
import TreeSitterRustRunestone
import TreeSitterJavaRunestone
import TreeSitterTypeScriptRunestone

/// Language mode configuration for Runestone text editor
struct TreeSitterLanguageMode {
    let language: TreeSitterLanguage
    let name: String
    let fileExtensions: [String]
    let icon: String
}

/// Comprehensive file type detection, icon mapping, and TreeSitter language mode utility
struct LanguageMapper {
    
    // MARK: - TreeSitter Language Modes
    
    /// All available TreeSitter language modes
    static let languageModes: [TreeSitterLanguageMode] = [
        TreeSitterLanguageMode(
            language: .javaScript,
            name: "JavaScript",
            fileExtensions: ["js", "jsx", "mjs"],
            icon: "doc.text.fill"
        ),
        TreeSitterLanguageMode(
            language: .python,
            name: "Python",
            fileExtensions: ["py", "pyw", "pyi"],
            icon: "doc.text.fill"
        ),
        TreeSitterLanguageMode(
            language: .swift,
            name: "Swift",
            fileExtensions: ["swift"],
            icon: "swift"
        ),
        TreeSitterLanguageMode(
            language: .json,
            name: "JSON",
            fileExtensions: ["json", "jsonc"],
            icon: "doc.badge.gearshape"
        ),
        TreeSitterLanguageMode(
            language: .html,
            name: "HTML",
            fileExtensions: ["html", "htm", "xhtml"],
            icon: "globe"
        ),
        TreeSitterLanguageMode(
            language: .css,
            name: "CSS",
            fileExtensions: ["css"],
            icon: "paintbrush"
        ),
        TreeSitterLanguageMode(
            language: .yaml,
            name: "YAML",
            fileExtensions: ["yaml", "yml"],
            icon: "doc.badge.gearshape"
        ),
        TreeSitterLanguageMode(
            language: .markdown,
            name: "Markdown",
            fileExtensions: ["md", "markdown", "mdown", "mkd"],
            icon: "doc.richtext"
        ),
        TreeSitterLanguageMode(
            language: .bash,
            name: "Shell",
            fileExtensions: ["sh", "bash", "zsh", "fish"],
            icon: "terminal"
        ),
        TreeSitterLanguageMode(
            language: .c,
            name: "C",
            fileExtensions: ["c", "h"],
            icon: "doc.text.fill"
        ),
        TreeSitterLanguageMode(
            language: .cpp,
            name: "C++",
            fileExtensions: ["cpp", "cxx", "cc", "hpp", "hxx", "hh"],
            icon: "doc.text.fill"
        ),
        TreeSitterLanguageMode(
            language: .go,
            name: "Go",
            fileExtensions: ["go"],
            icon: "doc.text.fill"
        ),
        TreeSitterLanguageMode(
            language: .rust,
            name: "Rust",
            fileExtensions: ["rs"],
            icon: "doc.text.fill"
        ),
        TreeSitterLanguageMode(
            language: .java,
            name: "Java",
            fileExtensions: ["java"],
            icon: "doc.text.fill"
        ),
        TreeSitterLanguageMode(
            language: .typeScript,
            name: "TypeScript",
            fileExtensions: ["ts", "tsx"],
            icon: "doc.text.fill"
        )
    ]
    
    /// Returns the appropriate TreeSitter language mode for a file path
    static func languageMode(for filePath: String) -> TreeSitterLanguageMode? {
        let fileExtension = (filePath as NSString).pathExtension.lowercased()
        return languageModes.first { $0.fileExtensions.contains(fileExtension) }
    }
    
    // MARK: - File Type Detection
    
    /// All supported code file extensions
    private static let codeExtensions: Set<String> = [
        // JavaScript family
        "js", "jsx", "mjs", "ts", "tsx",
        // Python
        "py", "pyw", "pyi",
        // Swift
        "swift",
        // Web technologies
        "html", "htm", "xhtml", "css", "scss", "sass", "less",
        // Data formats
        "json", "jsonc", "yaml", "yml", "toml", "xml",
        // Documentation
        "md", "markdown", "mdown", "mkd", "rst", "txt",
        // System programming
        "c", "h", "cpp", "cc", "cxx", "hpp", "hxx", "hh", "rs", "go", "java",
        // Shell scripts
        "sh", "bash", "zsh", "fish",
        // Other languages
        "rb", "php", "kt", "scala", "cs", "vb", "pl", "pm", "lua", "vim", "el",
        "clj", "cljs", "hs", "ml", "fs", "pas", "asm", "s", "dart", "jl", "r", "m", "mm",
        // Configuration files
        "dockerfile", "makefile", "cmake", "gradle", "properties", "ini", "conf", 
        "cfg", "env", "gitignore", "gitattributes", "editorconfig"
    ]
    
    /// All supported image file extensions
    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp", "tiff", "tif", "ico", "heic", "heif", "avif"
    ]
    
    /// Determines if a file is a code file based on its extension
    static func isCodeFile(_ fileName: String) -> Bool {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        return codeExtensions.contains(fileExtension)
    }
    
    /// Determines if a file is an image file based on its extension
    static func isImageFile(_ fileName: String) -> Bool {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        return imageExtensions.contains(fileExtension)
    }
    
    // MARK: - Icon Mapping
    
    /// Returns an appropriate SF Symbol icon name for a file
    static func fileIcon(for fileName: String, isDirectory: Bool = false) -> String {
        if isDirectory {
            return "folder.fill"
        }
        
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        // Check if we have a TreeSitter language mode for this file
        if let languageMode = languageMode(for: fileName) {
            return languageMode.icon
        }
        
        // Fallback to extension-based icon mapping
        switch fileExtension {
        case "rb", "php", "kt", "scala", "cs", "vb", "pl", "pm", "lua":
            return "doc.text.fill"
        case "scss", "sass", "less":
            return "paintbrush"
        case "xml":
            return "chevron.left.forwardslash.chevron.right"
        case "txt":
            return "doc.text"
        case "pdf":
            return "doc.richtext"
        case "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm":
            return "video"
        case "mp3", "wav", "flac", "aac", "ogg", "wma", "m4a":
            return "music.note"
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return "doc.zipper"
        case "dockerfile":
            return "shippingbox"
        case "makefile", "cmake":
            return "hammer"
        case "gitignore", "gitattributes":
            return "arrow.branch"
        case "env", "properties", "ini", "conf", "cfg":
            return "gearshape"
        default:
            if imageExtensions.contains(fileExtension) {
                return "photo"
            }
            return "doc"
        }
    }
    
    // MARK: - Display Names
    
    /// Get display name for file type
    static func displayName(for filePath: String) -> String {
        // Check if we have a TreeSitter language mode for this file
        if let languageMode = languageMode(for: filePath) {
            return languageMode.name
        }
        
        let fileExtension = (filePath as NSString).pathExtension.lowercased()
        
        // Fallback to extension-based display name mapping
        switch fileExtension {
        case "rb": return "Ruby"
        case "php": return "PHP"
        case "kt": return "Kotlin"
        case "scala": return "Scala"
        case "cs": return "C#"
        case "vb": return "Visual Basic"
        case "pl", "pm": return "Perl"
        case "lua": return "Lua"
        case "vim": return "Vim Script"
        case "el": return "Emacs Lisp"
        case "clj", "cljs": return "Clojure"
        case "hs": return "Haskell"
        case "ml": return "OCaml"
        case "fs": return "F#"
        case "pas": return "Pascal"
        case "asm", "s": return "Assembly"
        case "dart": return "Dart"
        case "jl": return "Julia"
        case "r": return "R"
        case "m", "mm": return "Objective-C"
        case "dockerfile": return "Dockerfile"
        case "makefile": return "Makefile"
        case "cmake": return "CMake"
        case "gradle": return "Gradle"
        case "properties": return "Properties"
        case "ini": return "INI"
        case "conf", "cfg": return "Configuration"
        case "env": return "Environment"
        case "gitignore": return "Git Ignore"
        case "gitattributes": return "Git Attributes"
        case "editorconfig": return "EditorConfig"
        case "toml": return "TOML"
        case "xml": return "XML"
        case "rst": return "reStructuredText"
        case "scss": return "SCSS"
        case "sass": return "Sass"
        case "less": return "Less"
        default: return "Text"
        }
    }
}