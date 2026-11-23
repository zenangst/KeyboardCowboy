import CoreGraphics
@testable import MouseFeature
import Testing

@MainActor
@Test func mouseExecutionPostsResolvedTargetAndReturnsPostingResult() async throws {
  let point = CGPoint(x: -40, y: 60)
  var resolved = false
  var posts = 0
  let result = try await Mouse.execute(.rightClick, resolve: {
    resolved = true
    return point
  }, post: { kind, target in
    #expect(resolved)
    #expect(kind == .rightClick)
    #expect(target == point)
    posts += 1
    return false
  })
  #expect(posts == 1)
  #expect(!result)
}

@MainActor
@Test func mouseExecutionSkipsPostingOnMissOrResolutionFailure() async throws {
  enum Failure: Error { case resolution }
  func unexpectedPost(_ kind: Mouse.ClickKind, _ point: CGPoint) -> Bool {
    Issue.record("Unexpected mouse post")
    return true
  }
  let result = try await Mouse.execute(.click, resolve: { nil }, post: unexpectedPost)
  #expect(!result)
  await #expect(throws: Failure.resolution) {
    try await Mouse.execute(.click, resolve: { throw Failure.resolution }, post: unexpectedPost)
  }
}

@MainActor
@Test func mouseExecutionDoesNotPostIfCancelledDuringResolution() async {
  let task = Task {
    try await Mouse.execute(.click, resolve: {
      withUnsafeCurrentTask { $0?.cancel() }
      return .zero
    }, post: { _, _ in
      Issue.record("Unexpected mouse post after cancellation")
      return true
    })
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}
