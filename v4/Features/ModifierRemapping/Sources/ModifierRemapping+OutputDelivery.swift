public extension ModifierRemapping {
  /// Tracks logical presses accepted by an output sink, not system delivery.
  /// A throwing sink must report an event it did not submit.
  struct OutputDelivery: Sendable {
    public enum Failure: Error { case recoveryRequired }

    private var pressed: [UInt16] = []
    public private(set) var needsRecovery = false

    public init() {}

    /// Unmatched releases are ignored. On failure, stop delivering new output
    /// until the caller resets the input session and recovers accepted presses.
    public mutating func send(_ output: [Event], using sink: (Event) throws -> Void) throws {
      guard !needsRecovery else { throw Failure.recoveryRequired }

      do {
        for event in output {
          let index = pressed.firstIndex(of: event.keyCode)
          switch event.phase {
          case .down where index == nil:
            try sink(event)
            pressed.append(event.keyCode)
          case .up:
            guard let index else { continue }
            try sink(event)
            pressed.remove(at: index)
          case .repeated where index != nil:
            try sink(event)
          default: continue
          }
        }
      } catch {
        needsRecovery = true
        throw error
      }
    }

    /// Release accepted presses in reverse order. Retry after a failed
    /// cleanup; releases already accepted by the sink are not repeated.
    public mutating func recover(using sink: (Event) throws -> Void) throws {
      needsRecovery = true
      while let keyCode = pressed.last {
        try sink(.init(keyCode: keyCode, phase: .up))
        pressed.removeLast()
      }
      needsRecovery = false
    }
  }
}
