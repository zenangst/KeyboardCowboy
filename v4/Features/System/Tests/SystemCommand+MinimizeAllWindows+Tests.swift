import Foundation
@testable import SystemFeature
import Testing
import UserSpace

private typealias MinimizeAllWindows = SystemFeature.Operation.MinimizeAllWindows

@Test @MainActor func minimizeAllUsesSnapshotOrderAndDeduplicatesCatalogApps() async throws {
  var pressed: [Int32] = []
  let operation = MinimizeAllWindows(
    windowOwners: { Issue.record("Unexpected live window query"); return [] },
    applications: {
      [.init(name: "A", bundleID: "a", pid: 1), .init(name: "A", bundleID: "a", pid: 2),
       .init(name: "B", bundleID: "b", pid: 3), .init(name: "Unlisted", bundleID: "c", pid: 4),
       .init(name: "No ID", bundleID: nil, pid: 5)]
    },
    catalogBundleIDs: { ["a", "b"] },
    pressMinimizeAll: { pressed.append($0) },
  )
  try await operation(["B", "Unlisted", "No ID", "Missing", "A", "B", "A"])
  #expect(pressed == [3, 1])
}

@Test @MainActor func minimizeAllUsesLiveOwnersOnlyWhenSnapshotIsAbsent() async throws {
  var reads = 0
  var pressed: [Int32] = []
  let operation = MinimizeAllWindows(
    windowOwners: { reads += 1; return ["A"] },
    applications: { [.init(name: "A", bundleID: "a", pid: 1)] },
    catalogBundleIDs: { ["a"] },
    pressMinimizeAll: { pressed.append($0) },
  )

  try await operation([])
  #expect(reads == 0)
  #expect(pressed.isEmpty)
  try await operation(nil)
  #expect(reads == 1)
  #expect(pressed == [1])
}

private enum MinimizeFailure: Error {
  case pressFailed
}

@Test(arguments: [true, false])
@MainActor func minimizeAllDoesNotPressLaterAppsAfterFailureOrCancellation(cancel: Bool) async {
  var pressed: [Int32] = []
  let operation = MinimizeAllWindows(
    windowOwners: { ["A", "B"] },
    applications: { [.init(name: "A", bundleID: "a", pid: 1), .init(name: "B", bundleID: "b", pid: 2)] },
    catalogBundleIDs: { ["a", "b"] },
    pressMinimizeAll: { pid in
      pressed.append(pid)
      if cancel {
        withUnsafeCurrentTask { $0?.cancel() }
      } else {
        throw MinimizeFailure.pressFailed
      }
    },
  )
  let task = Task { @MainActor in try await operation(nil) }
  if cancel {
    await #expect(throws: CancellationError.self) { try await task.value }
  } else {
    await #expect(throws: MinimizeFailure.pressFailed) { try await task.value }
  }
  #expect(pressed == [1])
}

@Test @MainActor func dispatchesMinimizeAllOpenWindowsWithSnapshotOwners() async throws {
  let action = try JSONDecoder().decode(SystemCommand.Action.self, from: Data(#""minimizeAllOpenWindows""#.utf8))
  var requests: [[String]?] = []
  let executor = SystemCommand.Executor(
    sendDockNotification: { _ in Issue.record("Unexpected Dock notification") },
    previousApplication: {
      Issue.record("Unexpected app history lookup")
      return (nil, UserSpace.Snapshot(apps: .init()))
    },
    openApplication: { _, _, _ in Issue.record("Unexpected application open") },
    minimizeAllOpenWindows: { requests.append($0) },
  )
  #expect(try await executor.run(action, visibleWindowOwners: ["A", "B"]) == .invoked)
  #expect(try await executor.run(action) == .invoked)
  #expect(requests == [["A", "B"], nil])
}
