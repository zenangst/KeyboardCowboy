public extension AccessibilitySystem {
  struct FrameWriteFailure: Error {
    public enum Step: Sendable {
      case position, size, readback
    }

    /// Writes before this step were acknowledged by AX, not necessarily applied
    /// exactly as requested. The failed step may have had side effects.
    public let step: Step
    public let cause: any Error
  }
}
