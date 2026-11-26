import Foundation

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
