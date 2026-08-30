import Foundation

public enum CodexAppServerClientError: LocalizedError, Sendable {
    case executableUnavailable
    case launchFailed
    case timedOut
    case serverExited

    public var errorDescription: String? {
        switch self {
        case .executableUnavailable:
            return "未找到 ChatGPT 内置的 Codex"
        case .launchFailed:
            return "无法启动 Codex 用量服务"
        case .timedOut:
            return "读取 Codex 用量超时"
        case .serverExited:
            return "Codex 用量服务意外退出"
        }
    }
}

public struct CodexAppServerClient: Sendable {
    public let executableURL: URL

    public init(executableURL: URL) {
        self.executableURL = executableURL
    }

    public static func resolved() throws -> CodexAppServerClient {
        guard let executableURL = CodexExecutableResolver.resolve() else {
            throw CodexAppServerClientError.executableUnavailable
        }
        return CodexAppServerClient(executableURL: executableURL)
    }

    public func readRateLimits(timeout: TimeInterval = 12) throws -> AppServerRateLimitsResponse {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice

        let exchange = AppServerExchange(input: inputPipe.fileHandleForWriting)
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            exchange.consume(handle.availableData)
        }
        process.terminationHandler = { _ in
            exchange.finishIfPending(.failure(CodexAppServerClientError.serverExited))
        }

        do {
            try process.run()
            try exchange.start()
        } catch is AppServerProtocolError {
            cleanup(process: process, input: inputPipe, output: outputPipe)
            throw AppServerProtocolError.invalidState
        } catch {
            cleanup(process: process, input: inputPipe, output: outputPipe)
            throw CodexAppServerClientError.launchFailed
        }

        let waitResult = exchange.semaphore.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
            exchange.finishIfPending(.failure(CodexAppServerClientError.timedOut))
        }
        cleanup(process: process, input: inputPipe, output: outputPipe)

        guard let result = exchange.result else {
            throw CodexAppServerClientError.serverExited
        }
        return try result.get()
    }

    private func cleanup(process: Process, input: Pipe, output: Pipe) {
        output.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
        try? input.fileHandleForWriting.close()
        try? output.fileHandleForReading.close()
        if process.isRunning {
            process.terminate()
        }
    }
}

private final class AppServerExchange: @unchecked Sendable {
    let semaphore = DispatchSemaphore(value: 0)

    private let lock = NSLock()
    private let input: FileHandle
    private var buffer = Data()
    private var session = AppServerProtocolSession()
    private var storedResult: Result<AppServerRateLimitsResponse, Error>?

    init(input: FileHandle) {
        self.input = input
    }

    var result: Result<AppServerRateLimitsResponse, Error>? {
        lock.withLock { storedResult }
    }

    func start() throws {
        let request = try lock.withLock { try session.initialRequest() }
        try send(request)
    }

    func consume(_ data: Data) {
        guard !data.isEmpty else {
            finishIfPending(.failure(CodexAppServerClientError.serverExited))
            return
        }

        var lines: [Data] = []
        lock.withLock {
            buffer.append(data)
            while let newline = buffer.firstIndex(of: 0x0A) {
                lines.append(Data(buffer[..<newline]))
                buffer.removeSubrange(...newline)
            }
        }

        for line in lines where !line.isEmpty {
            do {
                let event = try lock.withLock { try session.receive(line: line) }
                switch event {
                case .none:
                    break
                case let .send(messages):
                    try messages.forEach(send)
                case let .complete(response):
                    finishIfPending(.success(response))
                }
            } catch {
                finishIfPending(.failure(error))
            }
        }
    }

    func finishIfPending(_ result: Result<AppServerRateLimitsResponse, Error>) {
        let shouldSignal = lock.withLock {
            guard storedResult == nil else {
                return false
            }
            storedResult = result
            return true
        }
        if shouldSignal {
            semaphore.signal()
        }
    }

    private func send(_ data: Data) throws {
        var line = data
        line.append(0x0A)
        do {
            try input.write(contentsOf: line)
        } catch {
            throw CodexAppServerClientError.serverExited
        }
    }
}
