//
//  NetworkScanner.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import Network

#if canImport(Darwin)
import Darwin
#endif

/// Modern network scanning service for Roo Code discovery
@MainActor
final class NetworkScanner {
    
    // MARK: - Types
    
    struct NetworkInfo {
        let localIP: String
        let networkSegment: String
        let interfaceName: String
    }
    
    // MARK: - Properties
    
    private let discoveryPort: Int = 8766
    private let scanTimeout: TimeInterval = 2.0
    private let maxConcurrentScans: Int = 50
    private let logger = JoyPoseLogger.shared
    
    // MARK: - Public Methods
    
    /// Get local network information
    func getNetworkInfo() async -> NetworkInfo? {
        guard let localIP = await getLocalIPAddress() else { return nil }
        
        let networkSegment = calculateNetworkSegment(from: localIP)
        let interfaceName = getInterfaceName(for: localIP) ?? "unknown"
        
        return NetworkInfo(
            localIP: localIP,
            networkSegment: networkSegment,
            interfaceName: interfaceName
        )
    }
    
    /// Scan local network for Roo Code services
    func scanForServices() async -> [RooCodeService] {
        guard let networkInfo = await getNetworkInfo() else {
            logger.error("🔍 [DEBUG] Failed to get network information", category: .connection)
            return []
        }
        
        logger.info("🔍 [DEBUG] Starting network scan - Local IP: \(networkInfo.localIP), Network: \(networkInfo.networkSegment), Interface: \(networkInfo.interfaceName), Port: \(discoveryPort)", category: .connection)
        
        let ipAddresses = generateIPAddresses(from: networkInfo.networkSegment)
        
        return await withTaskGroup(of: RooCodeService?.self, returning: [RooCodeService].self) { group in
            let semaphore = AsyncSemaphore(value: maxConcurrentScans)
            
            for ip in ipAddresses {
                group.addTask {
                    await semaphore.wait()
                    defer { 
                        Task { await semaphore.signal() }
                    }
                    return await self.discoverService(at: ip)
                }
            }
            
            var services: [RooCodeService] = []
            for await service in group {
                if let service = service {
                    services.append(service)
                    logger.info("🔍 [DEBUG] Found Roo Code service: \(service.name) at \(service.websocketURL)", category: .connection)
                }
            }
            
            logger.info("🔍 [DEBUG] Network scan completed. Scanned 254 IPs, found \(services.count) services", category: .connection)
            return services
        }
    }
    
    // MARK: - Private Methods
    
    private func getLocalIPAddress() async -> String? {
        return await withCheckedContinuation { continuation in
            var address: String?
            
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddr) == 0 else {
                continuation.resume(returning: nil)
                return
            }
            defer { freeifaddrs(ifaddr) }
            
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "en1" { // Wi-Fi or Ethernet
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            
            continuation.resume(returning: address)
        }
    }
    
    private func calculateNetworkSegment(from ip: String) -> String {
        let components = ip.split(separator: ".").map(String.init)
        guard components.count == 4 else { return "192.168.1" }
        
        return "\(components[0]).\(components[1]).\(components[2])"
    }
    
    private func getInterfaceName(for ip: String) -> String? {
        // This is a simplified version - in a real implementation,
        // you might want to determine the actual interface name
        return "en0"
    }
    
    private func generateIPAddresses(from networkSegment: String) -> [String] {
        return (1...254).map { "\(networkSegment).\($0)" }
    }
    
    private func discoverService(at ip: String) async -> RooCodeService? {
        let urlString = "http://\(ip):\(discoveryPort)/discover"
        guard let url = URL(string: urlString) else { 
            logger.warning("🔍 [DEBUG] Invalid URL: \(urlString)", category: .connection)
            return nil 
        }
        
        // Log every 50th IP to avoid spam
        let ipLastOctet = Int(ip.split(separator: ".").last ?? "0") ?? 0
        if ipLastOctet % 50 == 0 {
            logger.debug("🔍 [DEBUG] Scanning IP: \(ip) (progress: \(ipLastOctet)/254)", category: .connection)
        }
        
        do {
            let request = URLRequest(url: url, timeoutInterval: scanTimeout)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                if let httpResponse = response as? HTTPURLResponse {
                    logger.debug("🔍 [DEBUG] No service at \(ip) - Status: \(httpResponse.statusCode)", category: .connection)
                }
                return nil
            }
            
            logger.info("🔍 [DEBUG] SUCCESS! Found service at \(ip) - Status: 200, Data size: \(data.count) bytes", category: .connection)
            
            let serviceInfo = try JSONDecoder().decode(RooCodeServiceInfo.self, from: data)
            logger.info("🔍 [DEBUG] Decoded service info: name=\(serviceInfo.name), ws_url=\(serviceInfo.websocket_url), version=\(serviceInfo.version)", category: .connection)
            
            guard let websocketURL = URL(string: serviceInfo.websocket_url) else {
                logger.warning("🔍 [DEBUG] Invalid WebSocket URL: \(serviceInfo.websocket_url)", category: .connection)
                return nil
            }
            
            let service = RooCodeService(
                name: serviceInfo.name,
                websocketURL: websocketURL,
                version: serviceInfo.version,
                platform: serviceInfo.platform,
                app: serviceInfo.app,
                capabilities: serviceInfo.capabilities
            )
            
            logger.info("🔍 [DEBUG] Created RooCodeService successfully for \(ip)", category: .connection)
            return service
            
        } catch {
            // Only log significant errors, not connection timeouts
            if !(error is URLError) || (error as? URLError)?.code != .timedOut {
                logger.debug("🔍 [DEBUG] Error at \(ip): \(error.localizedDescription)", category: .connection)
            }
            return nil
        }
    }
}

// MARK: - Supporting Types

/// Roo Code HTTP 发现服务响应格式 - 与服务器完全匹配
private struct RooCodeServiceInfo: Codable {
    let name: String
    let websocket_url: String
    let version: String
    let platform: String
    let app: String
    let capabilities: [String]
}

// MARK: - AsyncSemaphore

/// A simple async semaphore implementation for controlling concurrency
@MainActor
final class AsyncSemaphore {
    private let value: Int
    private var currentValue: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
        self.currentValue = value
    }
    
    func wait() async {
        if currentValue > 0 {
            currentValue -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    func signal() {
        if waiters.isEmpty {
            currentValue = min(currentValue + 1, value)
        } else {
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}