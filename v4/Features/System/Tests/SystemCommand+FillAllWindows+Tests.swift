import Foundation
@testable import SystemFeature
import Testing
import UserSpace

private typealias FillAllWindows = SystemFeature.Operation.FillAllWindows

@Test @MainActor func fillAllVisitsIntersectingWindowsInReverseAndForcesTheLast() async throws {
  let bounds = CGRect(x: -1000, y: 50, width: 1000, height: 800)
  let windows: [FillAllWindows.Window] = [
    .init(id: 1, pid: 1, bounds: CGRect(x: -430, y: 200, width: 500, height: 400)),
    .init(id: 2, pid: 2, bounds: CGRect(x: 0, y: 0, width: 500, height: 400)),
    .init(id: 3, pid: 1, bounds: bounds),
  ]
  var ids: [UInt32] = []
  var skipFrames: [CGRect?] = []
  let operation = FillAllWindows(display: { .init(visibleBounds: bounds, spacing: 8) },
                                 windows: { windows }, fill: { window, skipFrame in
                                   ids.append(window.id)
                                   skipFrames.append(skipFrame)
                                 })

  try await operation()
  #expect(ids == [3, 1])
  #expect(skipFrames == [bounds.insetBy(dx: 8, dy: 8), nil])
}

@Test @MainActor func fillAllWithoutDisplayDoesNotQueryWindows() async throws {
  let operation = FillAllWindows(display: { nil }, windows: {
    Issue.record("Unexpected window inventory query")
    return []
  }, fill: { _, _ in Issue.record("Unexpected Fill action") })
  try await operation()
}

private enum FillFailure: Error { case unavailable }

@Test(arguments: [false, true])
@MainActor func fillAllStopsAfterAnErrorOrCancellation(cancel: Bool) async {
  let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
  var ids: [UInt32] = []
  let operation = FillAllWindows(display: { .init(visibleBounds: bounds, spacing: 0) },
                                 windows: { [.init(id: 1, pid: 1, bounds: bounds), .init(id: 2, pid: 1, bounds: bounds)] },
                                 fill: { window, _ in
                                   ids.append(window.id)
                                   if cancel { withUnsafeCurrentTask { $0?.cancel() } } else { throw FillFailure.unavailable }
                                 })
  let task = Task { @MainActor in try await operation() }
  if cancel {
    await #expect(throws: CancellationError.self) { try await task.value }
  } else {
    await #expect(throws: FillFailure.unavailable) { try await task.value }
  }
  #expect(ids == [2])
}

@Test @MainActor func executorAwaitsPersistedFillAllAction() async throws {
  let data = Data(#""fillAllOpenWindows""#.utf8)
  let action = try JSONDecoder().decode(SystemCommand.Action.self, from: data)
  var calls = 0
  let executor = SystemCommand.Executor(
    sendDockNotification: { _ in Issue.record("Unexpected Dock notification") },
    previousApplication: {
      Issue.record("Unexpected snapshot")
      return (nil, UserSpace.Snapshot(apps: .init()))
    },
    openApplication: { _, _, _ in Issue.record("Unexpected application open") },
    fillAllOpenWindows: {
      await Task.yield()
      calls += 1
    },
  )
  #expect(try await executor.run(action) == .invoked)
  #expect(calls == 1)
  #expect(try JSONEncoder().encode(action) == data)
}
