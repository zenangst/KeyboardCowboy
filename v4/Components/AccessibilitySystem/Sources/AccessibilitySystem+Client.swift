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
      try await withSession(
        root: { $0.application(processIdentifier) },
        operation: operation)
    }

    /// Captures system-wide focus once. The closure cannot suspend, and the
    /// focused element's operations are valid only during this transaction.
    public func withFocusedElement<Value: Sendable>(
      _ operation: @escaping @Sendable (FocusedElement) throws -> Value,
    ) async throws -> Value {
      try await withSession(
        root: { try $0.focusedElement() },
        operation: { session in
          try operation(FocusedElement(session: session))
        })
    }

    private func withSession<Value: Sendable>(
      root: @escaping @Sendable (any Transport) throws -> Handle,
      operation: @escaping @Sendable (Session) throws -> Value,
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
                let transport = makeTransport()
                try request.check()
                let session = try Session(
                  root: root(transport),
                  transport: transport,
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

  struct FocusedElement {
    fileprivate let session: Session

    public func read<Value>(_ attribute: Attribute<Value>) throws -> Value {
      try session.read(attribute, of: session.application)
    }

    public func write(_ attribute: WritableAttribute<String>, value: String) throws {
      try session.write(attribute, value: value, to: session.application)
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
