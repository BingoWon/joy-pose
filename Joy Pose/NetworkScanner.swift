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
    
    // MARK: - Public Methods
    
    /// Get local network information
    func getNetworkInfo() async -> NetworkInfo? {
        guard let localIP = await getLocalIPAddress() else { return nil }
        
        let networkSegment = calculateNetworkSegment(from: localIP)
        let interfaceName = getInterfaceName() ?? "Unknown"
        
        return NetworkInfo(
            localIP: localIP,
            networkSegment: networkSegment,
            interfaceName: interfaceName
        )
    }
    
    /// Scan network segment for Roo Code services
    func scanForServices(in networkSegment: String) async -> [RooCodeService] {
        let ipAddresses = generateIPAddresses(from: networkSegment)
        
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
                }
            }
            return services
        }
    }
    
    // MARK: - Private Methods
    
    private func getLocalIPAddress() async -> String? {
        let interfaces = [
            "en0",  // WiFi
            "en1",  // Ethernet
            "pdp_ip0", // Cellular
            "awdl0" // AirDrop
        ]
        
        for interfaceName in interfaces {
            if let address = getIPAddress(for: interfaceName) {
                return address
            }
        }
        
        return nil
    }
    
    private func getIPAddress(for interfaceName: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee,
                  let addrPtr = interface.ifa_addr,
                  addrPtr.pointee.sa_family == UInt8(AF_INET),
                  String(cString: interface.ifa_name) == interfaceName else {
                continue
            }
            
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addrPtr, socklen_t(interface.ifa_addr.pointee.sa_len),
                          &hostname, socklen_t(hostname.count),
                          nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                return String(cString: hostname)
            }
        }
        
        return nil
    }
    
    private func getInterfaceName() -> String? {
        let interfaces = ["en0", "en1", "pdp_ip0"]
        for interface in interfaces {
            if getIPAddress(for: interface) != nil {
                return interface
            }
        }
        return nil
    }
    
    private func calculateNetworkSegment(from ip: String) -> String {
        let components = ip.split(separator: ".").compactMap { Int($0) }
        guard components.count == 4 else { return "\(ip)/32" }
        
        return "\(components[0]).\(components[1]).\(components[2]).0/24"
    }
    
    private func generateIPAddresses(from networkSegment: String) -> [String] {
        guard let baseIP = networkSegment.split(separator: "/").first else { return [] }
        let components = baseIP.split(separator: ".").compactMap { Int($0) }
        guard components.count == 4 else { return [] }
        
        let baseNetwork = "\(components[0]).\(components[1]).\(components[2])"
        return (1...254).map { "\(baseNetwork).\($0)" }
    }
    
    private func discoverService(at ipAddress: String) async -> RooCodeService? {
        let url = URL(string: "http://\(ipAddress):\(discoveryPort)/discover")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = scanTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            return try JSONDecoder().decode(RooCodeService.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - AsyncSemaphore

/// Simple async semaphore for controlling concurrency
private actor AsyncSemaphore {
    private let maxCount: Int
    private var currentCount: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.maxCount = value
        self.currentCount = value
    }
    
    func wait() async {
        if currentCount > 0 {
            currentCount -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            currentCount = min(currentCount + 1, maxCount)
        }
    }
}
