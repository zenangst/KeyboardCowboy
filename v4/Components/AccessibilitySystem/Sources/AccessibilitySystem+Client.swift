import Dispatch
import Foundation

public extension AccessibilitySystem {
  /// Owns an off-main serial worker. No observer run loop is installed.
  /// Safety: immutable configuration/factory; all AX state is created on worker.
  final class Client: Sendable {
    private let queue = DispatchQueue(label: "AccessibilitySystem.worker")
    private let configuration: Configuration
    private let makeTransport: @Sendable () -> any Transport

    public convenience init(configuration: Configuration = .init()) {
      self.init(configuration: configuration,
                makeTransport: { NativeTransport() })
    }

    init(configuration: Configuration = .init(),
         makeTransport: @escaping @Sendable () -> any Transport) {
      self.configuration = configuration
      self.makeTransport = makeTransport
    }

    /// The closure cannot suspend. Its session and elements expire on return.
    /// Cancellation is checked between calls, not during synchronous AX IPC.
    public func withApplication<Value: Sendable>(
      processIdentifier: Int32,
      _ operation: @escaping @Sendable (Session) throws -> Value,
    ) async throws -> Value {
      let request = Request()
      return try await withTaskCancellationHandler {
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
          queue.async { [self] in
            do {
              try request.check()
              let seconds = Float(configuration.messagingTimeout.components.seconds)
                + Float(configuration.messagingTimeout.components.attoseconds) / 1e18
              guard seconds.isFinite, seconds > 0 else {
                throw Failure(.invalidConfiguration, operation: "messagingTimeout")
              }

              let value: Value
              do {
                let session = try Session(
                  pid: processIdentifier,
                  transport: makeTransport(),
                  timeout: seconds,
                  queue: queue,
                  request: request,
                )
                defer { session.invalidate() }
                value = try operation(session)
                try request.check()
              }
              continuation.resume(returning: value)
            } catch {
              continuation.resume(throwing: error)
            }
          }
        }
      } onCancel: {
        request.cancel()
      }
    }
  }
}

extension AccessibilitySystem {
  // Only this small cancellation bridge uses unchecked Sendable. The lock guards
  // all accesses, including cancellation from outside the worker.
  final class Request: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    func cancel() { lock.withLock { cancelled = true } }
    func check() throws {
      if lock.withLock({ cancelled }) { throw CancellationError() }
    }
  }
}
