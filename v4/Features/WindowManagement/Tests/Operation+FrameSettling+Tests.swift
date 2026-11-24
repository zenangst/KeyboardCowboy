import CoreGraphics
import Testing
@testable import WindowManagementFeature

@Test func frameSettlingCanRequireSizeAsWellAsOrigin() async throws {
  let target = CGRect(x: -400, y: 100, width: 200, height: 150)
  let operation = Operation.FrameSettling(origin: target.origin, size: target.size)
  let wrongSize = CGRect(origin: target.origin, size: CGSize(width: target.width, height: 210))
  let samples = [wrongSize, target, target.offsetBy(dx: 5, dy: 0), target, target]
  var count = 0
  let result = try await operation.whenSettled(sample: {
    guard count < samples.count else { return nil }

    defer { count += 1 }
    return samples[count]
  }, apply: { count })
  #expect(result == 5)
}

@Test func settledFillRequiresConsecutiveMatchesBeforeResizing() async throws {
  let target = CGRect(x: -200, y: 100, width: 420, height: 250)
  let operation = Operation.FrameSettling(origin: target.origin)
  var samples = [target, target.offsetBy(dx: 1, dy: 0), target, target]
  var writes = 0
  let result = try await operation.whenSettled(sample: {
    samples.isEmpty ? nil : samples.removeFirst()
  }, apply: {
    #expect(samples.isEmpty)
    writes += 1
    return true
  })
  #expect(result == true)
  #expect(writes == 1)
}

@Test func settledFillDoesNotResizeWhenTheWindowDisappears() async throws {
  let operation = Operation.FrameSettling(origin: .zero)
  var samples = 0
  let result = try await operation.whenSettled(sample: {
    samples += 1
    return samples == 1 ? CGRect(x: 0, y: 0, width: 400, height: 300) : nil
  }, apply: {
    Issue.record("The verified window disappeared")
    return true
  })
  #expect(samples == 2)
  #expect(result == nil)
}

@Test func settledFillDoesNotResizeAfterTimeout() async {
  let operation = Operation.FrameSettling(origin: .zero)
  await #expect(throws: WindowManagement.FramePlacementError.settlingTimedOut) {
    try await operation.whenSettled(timeout: .milliseconds(25), sample: {
      CGRect(x: 10, y: 0, width: 400, height: 300)
    }, apply: {
      Issue.record("The window did not settle")
      return true
    })
  }
}

@Test func settledFillDoesNotResizeWhenCancelledWhileSampling() async throws {
  let task = Task {
    let operation = Operation.FrameSettling(origin: .zero)
    await #expect(throws: CancellationError.self) {
      try await operation.whenSettled(sample: {
        withUnsafeCurrentTask { $0?.cancel() }
        return CGRect(x: 0, y: 0, width: 400, height: 300)
      }, apply: {
        Issue.record("The operation was cancelled")
        return true
      })
    }
  }
  await task.value
}

@Test func settledFillPropagatesTheResizeFailureWithoutRetry() async {
  enum Failure: Error { case resize }
  let operation = Operation.FrameSettling(origin: .zero)
  var writes = 0
  await #expect(throws: Failure.resize) {
    let _: Bool? = try await operation.whenSettled(sample: {
      CGRect(x: 0, y: 0, width: 400, height: 300)
    }, apply: {
      writes += 1
      throw Failure.resize
    })
  }
  #expect(writes == 1)
}
