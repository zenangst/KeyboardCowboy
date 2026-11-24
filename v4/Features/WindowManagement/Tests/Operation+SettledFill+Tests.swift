import CoreGraphics
import Testing
@testable import WindowManagementFeature

@Test func settledFillRequiresConsecutiveMatchesBeforeResizing() async throws {
  let target = CGRect(x: -200, y: 100, width: 420, height: 250)
  let operation = Operation.SettledFill(origin: target.origin)
  var samples = [target, target.offsetBy(dx: 1, dy: 0), target, target]
  var writes = 0
  let result = try await operation.resizeWhenSettled(sample: {
    samples.isEmpty ? nil : samples.removeFirst()
  }, resize: {
    #expect(samples.isEmpty)
    writes += 1
    return true
  })
  #expect(result == true)
  #expect(writes == 1)
}

@Test func settledFillDoesNotResizeWhenTheWindowDisappears() async throws {
  let operation = Operation.SettledFill(origin: .zero)
  var samples = 0
  let result = try await operation.resizeWhenSettled(sample: {
    samples += 1
    return samples == 1 ? CGRect(x: 0, y: 0, width: 400, height: 300) : nil
  }, resize: {
    Issue.record("The verified window disappeared")
    return true
  })
  #expect(samples == 2)
  #expect(result == nil)
}

@Test func settledFillDoesNotResizeAfterTimeout() async {
  let operation = Operation.SettledFill(origin: .zero)
  await #expect(throws: WindowManagement.FillError.settlingTimedOut) {
    try await operation.resizeWhenSettled(timeout: .milliseconds(25), sample: {
      CGRect(x: 10, y: 0, width: 400, height: 300)
    }, resize: {
      Issue.record("The window did not settle")
      return true
    })
  }
}

@Test func settledFillDoesNotResizeWhenCancelledWhileSampling() async throws {
  let task = Task {
    let operation = Operation.SettledFill(origin: .zero)
    await #expect(throws: CancellationError.self) {
      try await operation.resizeWhenSettled(sample: {
        withUnsafeCurrentTask { $0?.cancel() }
        return CGRect(x: 0, y: 0, width: 400, height: 300)
      }, resize: {
        Issue.record("The operation was cancelled")
        return true
      })
    }
  }
  await task.value
}

@Test func settledFillPropagatesTheResizeFailureWithoutRetry() async {
  enum Failure: Error { case resize }
  let operation = Operation.SettledFill(origin: .zero)
  var writes = 0
  await #expect(throws: Failure.resize) {
    let _: Bool? = try await operation.resizeWhenSettled(sample: {
      CGRect(x: 0, y: 0, width: 400, height: 300)
    }, resize: {
      writes += 1
      throw Failure.resize
    })
  }
  #expect(writes == 1)
}
