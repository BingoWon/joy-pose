//
//  WebSocketClient.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import Foundation
import Combine

/// WebSocket 代理类，处理连接状态变化
private class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // Connection closed - minimal logging
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
        // Connection opened - minimal logging
    }
}

/// 现代化 WebSocket 客户端 - 精简设计
@MainActor
@Observable
final class WebSocketClient {
    private(set) var connectionState: RooCodeConnectionState = .disconnected
    private(set) var lastError: String?

    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private var connectionId: String?

    private var pingTimer: Timer?

    private let messageSubject = PassthroughSubject<VisionMessage, Never>()
    var messagePublisher: AnyPublisher<VisionMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    /// Modern streaming message sequence for elegant async/await usage
    var messageStream: AsyncStream<VisionMessage> {
        AsyncStream { continuation in
            let cancellable = messageSubject
                .sink { message in
                    continuation.yield(message)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.urlSession = URLSession(configuration: config, delegate: WebSocketDelegate(), delegateQueue: nil)
    }

    deinit {
        // 在 deinit 中不能访问 MainActor 隔离的属性
        // 清理工作应该在 disconnect() 方法中完成
    }
    
    /// Modern connection to Roo Code service - Optimized connection flow
    func connect(to service: RooCodeService) async {
        guard let url = service.webSocketURL else {
            connectionState = .failed("Invalid URL")
            return
        }

        disconnect()
        connectionState = .connecting

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()

        startListening()

        // 发送现代化 VisionSync 握手
        let handshakeMessage = VisionMessage.clientHandshake()
        await sendMessage(handshakeMessage)
    }

    /// 断开连接
    func disconnect() {
        stopPingTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionId = nil
        connectionState = .disconnected
    }

    /// 清除错误状态
    func clearError() {
        lastError = nil
    }

    /// 发送消息 - 现代化设计
    func sendMessage(_ message: VisionMessage) async {
        guard connectionState.isConnected || connectionState == .connecting else {
            logger.warning("Cannot send message: not connected")
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            let messageString = String(data: data, encoding: .utf8) ?? ""
            let urlSessionMessage = URLSessionWebSocketTask.Message.string(messageString)

            try await webSocketTask?.send(urlSessionMessage)
            logger.debug("Message sent: \(message.type.rawValue)")
        } catch {
            lastError = "Send error: \(error.localizedDescription)"
            logger.error("Failed to send message: \(error.localizedDescription)")
        }
    }

    /// 开始监听消息
    private func startListening() {
        Task { @MainActor in
            await receiveMessage()
        }
    }

    /// 接收消息 - 递归监听
    private func receiveMessage() async {
        guard let webSocketTask = webSocketTask else { return }

        do {
            let message = try await webSocketTask.receive()
            await handleReceivedMessage(message)

            // 继续监听下一条消息
            await receiveMessage()
        } catch {
            if connectionState != .disconnected {
                connectionState = .failed("Connection lost: \(error.localizedDescription)")
                lastError = error.localizedDescription
            }
        }
    }

    /// 处理接收到的消息
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            await processTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                await processTextMessage(text)
            }
        @unknown default:
            logger.warning("Unknown message type received")
        }
    }

    /// 处理文本消息
    private func processTextMessage(_ text: String) async {
        do {
            let visionMessage = try JSONDecoder().decode(VisionMessage.self, from: Data(text.utf8))
            
            // 处理特殊消息类型
            switch visionMessage.type {
            case .connectionAccepted:
                connectionState = .connected
                startPingTimer()
            case .connectionRejected:
                connectionState = .failed("Connection rejected")
            case .pong:
                // Pong 响应 - 连接保活
                break
            default:
                break
            }

            // 发布消息给订阅者
            messageSubject.send(visionMessage)
        } catch {
            logger.error("Failed to decode message: \(error.localizedDescription)")
        }
    }

    /// 启动 Ping 定时器
    private func startPingTimer() {
        stopPingTimer()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendPing()
            }
        }
    }

    /// 停止 Ping 定时器
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    /// 发送 Ping 消息
    private func sendPing() async {
        let pingMessage = VisionMessage.ping()
        await sendMessage(pingMessage)
    }
}
