//
//  RemoteHostManager.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import Citadel

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

struct HostConfiguration: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let hostname: String
    let port: Int
    let username: String
    let password: String
    
    static func == (lhs: HostConfiguration, rhs: HostConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
}

struct RemoteFile: Identifiable, Codable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
}

@Observable
class RemoteHostManager {
    static let shared = RemoteHostManager()

    // MARK: - Properties
    var connectionState: ConnectionState = .disconnected
    var currentHost: HostConfiguration?
    var currentDirectory: String = "/root"
    var files: [RemoteFile] = []

    // MARK: - Private Properties
    private var sshClient: SSHClient?
    private var sftpClient: SFTPClient?

    private init() {}

    // MARK: - Connection Management

    /// Dynamically detect user home directory via SSH command
    private func detectHomeDirectory(_ client: SSHClient) async -> String {
        do {
            let output = try await client.executeCommand("pwd")
            let homeDir = String(buffer: output).trimmingCharacters(in: .whitespacesAndNewlines)
            return homeDir.isEmpty ? "/root" : homeDir
        } catch {
            logger.warning("Failed to detect home directory, using fallback: \(error.localizedDescription)", category: .terminal)
            return "/root"
        }
    }

    func connect(to host: HostConfiguration, password: String? = nil) async {
        await MainActor.run {
            connectionState = .connecting
            currentHost = host
        }

        do {
            logger.info("Starting SSH connection to \(host.hostname):\(host.port) as \(host.username)", category: .terminal)

            // Create SSH client settings
            let settings = SSHClientSettings(
                host: host.hostname,
                port: host.port,
                authenticationMethod: { .passwordBased(username: host.username, password: password ?? host.password) },
                hostKeyValidator: .acceptAnything() // For development - should use proper validation in production
            )

            // Connect to SSH server
            let client = try await SSHClient.connect(to: settings)
            self.sshClient = client

            logger.info("SSH connection established successfully", category: .terminal)

            await MainActor.run {
                connectionState = .connected
            }

            // Dynamically detect user home directory
            let homeDir = await detectHomeDirectory(client)

            await MainActor.run {
                currentDirectory = homeDir
            }

            // Initialize SFTP for file operations
            await initializeSFTP()

            // Load initial directory
            await loadDirectory()

        } catch {
            logger.error("SSH connection failed: \(error.localizedDescription)", category: .terminal)

            await MainActor.run {
                connectionState = .failed("Connection failed: \(error.localizedDescription)")
            }
        }
    }

    func disconnect() async {
        do {
            // Close SFTP client
            if let sftp = sftpClient {
                try await sftp.close()
                sftpClient = nil
            }

            // Close SSH client
            if let ssh = sshClient {
                try await ssh.close()
                sshClient = nil
            }

            logger.info("SSH connection closed", category: .terminal)

        } catch {
            logger.error("Error closing SSH connection: \(error.localizedDescription)", category: .terminal)
        }

        await MainActor.run {
            connectionState = .disconnected
            currentHost = nil
            currentDirectory = "/root"
            files = []
        }
    }

    // MARK: - SFTP Operations

    private func initializeSFTP() async {
        guard let ssh = sshClient else { return }

        do {
            let sftp = try await ssh.openSFTP()
            self.sftpClient = sftp

            logger.info("SFTP session initialized", category: .terminal)

        } catch {
            logger.error("Failed to initialize SFTP: \(error.localizedDescription)", category: .terminal)
        }
    }

    func loadDirectory(_ path: String? = nil) async {
        guard let sftp = sftpClient else {
            logger.warning("SFTP client not available", category: .terminal)
            return
        }

        let targetPath = path ?? currentDirectory

        do {
            // Use getRealPath to resolve the actual path first
            let realPath = try await sftp.getRealPath(atPath: targetPath)
            logger.debug("Real path resolved: \(realPath)", category: .terminal)

            // List directory contents using the resolved path
            let directoryContents = try await sftp.listDirectory(atPath: realPath)
            logger.debug("Directory listing successful, found \(directoryContents.count) items", category: .terminal)

            var remoteFiles: [RemoteFile] = []

            // Process each SFTPMessage.Name response
            for nameResponse in directoryContents {
                // Each nameResponse contains components (SFTPPathComponent array)
                for component in nameResponse.components {
                    let fileName = component.filename
                    let fullPath = "\(realPath)/\(fileName)"

                    // Skip current and parent directory entries
                    if fileName == "." || fileName == ".." {
                        continue
                    }

                    // Use the attributes from the component
                    let attributes = component.attributes

                    // Check if it's a directory based on permissions
                    var isDirectory = false
                    if let permissions = attributes.permissions {
                        // Check if it's a directory using bitwise operations
                        isDirectory = (permissions & 0o040000) != 0  // S_IFDIR
                    }

                    let fileSize = Int64(attributes.size ?? 0)

                    // Use modification time from attributes or current date as fallback
                    let modDate: Date
                    if let accessModTime = attributes.accessModificationTime {
                        modDate = accessModTime.modificationTime
                    } else {
                        modDate = Date()
                    }

                    let remoteFile = RemoteFile(
                        name: fileName,
                        path: fullPath,
                        isDirectory: isDirectory,
                        size: fileSize,
                        modificationDate: modDate
                    )

                    remoteFiles.append(remoteFile)
                }
            }

            // Sort files: directories first, then alphabetically
            remoteFiles.sort { file1, file2 in
                if file1.isDirectory != file2.isDirectory {
                    return file1.isDirectory
                }
                return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
            }

            await MainActor.run { [remoteFiles, realPath] in
                files = remoteFiles
                if path != nil {
                    currentDirectory = realPath
                }
            }

            logger.info("Successfully loaded \(remoteFiles.count) files from \(realPath)", category: .terminal)

        } catch {
            logger.error("Failed to load directory \(targetPath): \(error.localizedDescription)", category: .terminal)
        }
    }

    // MARK: - Command Execution

    func executeCommand(_ command: String) async -> String? {
        guard let ssh = sshClient else {
            logger.warning("SSH client not available", category: .terminal)
            return nil
        }

        do {
            let output = try await ssh.executeCommand(command)
            let outputString = String(buffer: output)
            logger.debug("Command executed: \(command)", category: .terminal)
            return outputString
        } catch {
            logger.error("Command execution failed: \(error.localizedDescription)", category: .terminal)
            return nil
        }
    }

    // MARK: - File Operations

    func deleteFile(_ file: RemoteFile) async throws {
        guard let sftp = sftpClient else { return }

        do {
            // Use remove method for both files and directories
            try await sftp.remove(at: file.path)

            logger.info("Deleted file: \(file.path)", category: .terminal)
            await loadDirectory()

        } catch {
            logger.error("Failed to delete file \(file.path): \(error.localizedDescription)", category: .terminal)
            throw error
        }
    }

    func changeDirectory(to path: String) async {
        await MainActor.run {
            currentDirectory = path
        }
        await loadDirectory()
    }
    
    // MARK: - Connection Testing
    
    func testConnection(_ config: HostConfiguration) async -> Bool {
        do {
            logger.info("Testing SSH connection to \(config.hostname):\(config.port)", category: .connection)
            
            let settings = SSHClientSettings(
                host: config.hostname,
                port: config.port,
                authenticationMethod: { .passwordBased(username: config.username, password: config.password) },
                hostKeyValidator: .acceptAnything()
            )
            
            let client = try await SSHClient.connect(to: settings)
            try await client.close()
            
            logger.info("Connection test successful", category: .connection)
            return true
        } catch {
            logger.error("Connection test failed: \(error.localizedDescription)", category: .connection)
            return false
        }
    }
}
