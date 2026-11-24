import CoreGraphics

extension Operation {
  struct FrameSettling: Sendable {
    let origin: CGPoint
    var size: CGSize? = nil

    func whenSettled<Result>(
      timeout: Duration = .seconds(1),
      sample: () -> CGRect?,
      apply: () async throws -> Result?,
    ) async throws -> Result? {
      let clock = ContinuousClock()
      let deadline = clock.now + timeout
      var consecutive = 0
      while clock.now < deadline {
        try Task.checkCancellation()
        guard let frame = sample() else { return nil }

        consecutive = matches(frame) ? consecutive + 1 : 0
        let now = clock.now
        if consecutive == 2, now < deadline {
          try Task.checkCancellation()
          return try await apply()
        }
        try await clock.sleep(until: min(now + .milliseconds(20), deadline))
      }
      try Task.checkCancellation()
      throw WindowManagement.FramePlacementError.settlingTimedOut
    }

    static func matchesOrigin(_ frame: CGRect, _ origin: CGPoint) -> Bool {
      abs(frame.minX - origin.x) <= 0.5 && abs(frame.minY - origin.y) <= 0.5
    }

    func matches(_ frame: CGRect) -> Bool {
      guard Self.matchesOrigin(frame, origin) else { return false }
      guard let size else { return true }

      return abs(frame.width - size.width) <= 0.5 && abs(frame.height - size.height) <= 0.5
    }
  }
}
