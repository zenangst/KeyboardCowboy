import CoreGraphics

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

public extension AccessibilitySystem.Session {
  /// Reads position then size in AX global screen coordinates. Not atomic.
  func frame(of element: AccessibilitySystem.Element) throws -> CGRect {
    try CGRect(origin: read(.position, of: element), size: read(.size, of: element))
  }

  func write(_ attribute: AccessibilitySystem.WritableAttribute<CGPoint>,
             value: CGPoint, to element: AccessibilitySystem.Element) throws {
    guard value.x.isFinite, value.y.isFinite else {
      throw AccessibilitySystem.Failure(.invalidConfiguration, operation: attribute.name)
    }

    try transportWrite(attribute.name, position: value, to: element)
  }

  func write(_ attribute: AccessibilitySystem.WritableAttribute<CGSize>,
             value: CGSize, to element: AccessibilitySystem.Element) throws {
    guard value.width.isFinite, value.height.isFinite, value.width >= 0, value.height >= 0 else {
      throw AccessibilitySystem.Failure(.invalidConfiguration, operation: attribute.name)
    }

    try transportWrite(attribute.name, size: value, to: element)
  }

  /// Writes position then size and reads back the observed frame, which may
  /// differ from the request. Stops on the first failure; never rolls back.
  func setFrame(_ frame: CGRect, of element: AccessibilitySystem.Element) throws -> CGRect {
    guard frame.origin.x.isFinite, frame.origin.y.isFinite,
          frame.size.width.isFinite, frame.size.height.isFinite,
          frame.size.width >= 0, frame.size.height >= 0,
          frame.maxX.isFinite, frame.maxY.isFinite else {
      throw AccessibilitySystem.Failure(.invalidConfiguration, operation: "setFrame")
    }

    var step = AccessibilitySystem.FrameWriteFailure.Step.position
    do {
      try write(.position, value: frame.origin, to: element)
      step = .size
      try write(.size, value: frame.size, to: element)
      step = .readback
      return try self.frame(of: element)
    } catch {
      throw AccessibilitySystem.FrameWriteFailure(step: step, cause: error)
    }
  }
}
