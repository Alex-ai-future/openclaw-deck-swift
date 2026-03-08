// WebSocketConnection.swift
// OpenClaw Deck Swift
//
// WebSocket 连接抽象 - 用于依赖注入和测试

import Foundation

/// WebSocket 连接协议
protocol WebSocketConnection: AnyObject, Sendable {
    /// 连接状态
    var state: URLSessionWebSocketTask.State { get }

    /// 恢复连接
    func resume()

    /// 取消连接
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)

    /// 发送消息
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void)

    /// 接收消息
    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
}

// MARK: - 真实实现

/// 真实 WebSocket 连接（委托给 URLSessionWebSocketTask）
final class RealWebSocketConnection: WebSocketConnection, @unchecked Sendable {
    private let task: URLSessionWebSocketTask

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    var state: URLSessionWebSocketTask.State {
        task.state
    }

    func resume() {
        task.resume()
    }

    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        task.cancel(with: closeCode, reason: reason)
    }

    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void) {
        task.send(message, completionHandler: completionHandler)
    }

    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        task.receive(completionHandler: completionHandler)
    }
}

// MARK: - Mock 实现（用于测试）

/// Mock WebSocket 连接 - 完全可控，用于单元测试
@MainActor
final class MockWebSocketConnection: WebSocketConnection {
    var state: URLSessionWebSocketTask.State = .running

    /// 发送回调（测试可以监听）
    var onSend: ((URLSessionWebSocketTask.Message) -> Void)?

    /// 接收消息生成器（测试可以控制）
    var messageGenerator: (() -> URLSessionWebSocketTask.Message)?

    /// 接收错误注入
    var receiveError: Error?

    /// 是否应该失败
    var shouldFail: Bool = false

    /// 失败延迟（纳秒）
    var failDelay: UInt64 = 100_000_000 // 100ms

    init() {}

    func resume() {
        state = .running
    }

    func cancel(with _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
        state = .suspended // URLSessionTask.State 没有 cancelled，使用 suspended
    }

    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void) {
        onSend?(message)

        if shouldFail {
            DispatchQueue.global().asyncAfter(deadline: .now() + Double(failDelay) / 1_000_000_000) {
                completionHandler(NSError(domain: "MockWebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock send failure"]))
            }
        } else {
            completionHandler(nil)
        }
    }

    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        if let error = receiveError {
            completionHandler(.failure(error))
            return
        }

        if let generator = messageGenerator {
            completionHandler(.success(generator()))
        } else {
            // 默认返回空消息
            completionHandler(.success(.string("")))
        }
    }

    /// 模拟接收消息（测试调用）
    func simulateReceive(_: URLSessionWebSocketTask.Message) {
        // 用于主动推送消息
    }

    /// 模拟断开连接（测试调用）
    func simulateDisconnect() {
        state = .suspended
    }

    /// 模拟重连成功（测试调用）
    func simulateReconnect() {
        state = .running
    }
}
