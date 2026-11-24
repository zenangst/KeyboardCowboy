import Foundation
@testable import SystemFeature
import Testing
import UserSpace

@MainActor
private final class ApplicationScript {
  enum Failure: Error { case open }
  let snapshot = UserSpace.Snapshot(apps: .init())
  var previous: SystemCommand.Executor.PreviousApplication? = .init(
    bundleIdentifier: "test.previous", bundleURL: URL(fileURLWithPath: "/Test Fixtures/Previous App.app"),
  )
  var calls: [String] = []
  var openError: (any Error)?
  var cancelDuringLookup = false

  var executor: SystemCommand.Executor {
    .init(
      sendDockNotification: { _ in Issue.record("Unexpected Dock notification") },
      previousApplication: {
        self.calls.append("lookup")
        if self.cancelDuringLookup { withUnsafeCurrentTask { $0?.cancel() } }
        return (self.previous, self.snapshot)
      },
      openApplication: { command, event, snapshot in
        self.calls.append("open")
        #expect(command.action == .open)
        #expect(command.modifiers.isEmpty)
        #expect(command.application.bundleIdentifier == "test.previous")
        #expect(command.application.bundleName == "Previous App")
        #expect(command.application.path == "/Test Fixtures/Previous App.app")
        #expect(event == nil)
        #expect(snapshot === self.snapshot)
        await Task.yield()
        if let error = self.openError { throw error }
        self.calls.append("completed")
      },
    )
  }
}

@Test @MainActor
func activateLastApplicationAwaitsOrdinaryOpen() async throws {
  let data = Data("\"activateLastApplication\"".utf8)
  let action = try JSONDecoder().decode(SystemCommand.Action.self, from: data)
  let script = ApplicationScript()

  #expect(try await script.executor.run(action) == .applicationOpenCompleted)
  #expect(script.calls == ["lookup", "open", "completed"])
  #expect(try JSONEncoder().encode(action) == data)
}

@Test @MainActor
func absentPreviousApplicationDoesNotOpen() async throws {
  let script = ApplicationScript()
  script.previous = nil

  #expect(try await script.executor.run(.activateLastApplication) == .noPreviousApplication)
  #expect(script.calls == ["lookup"])
}

@Test @MainActor
func missingPreviousApplicationBundleURLIsReported() async {
  let script = ApplicationScript()
  script.previous = .init(bundleIdentifier: "test.previous", bundleURL: nil)

  await #expect(throws: SystemCommand.ExecutionError.missingPreviousApplicationBundleURL("test.previous")) {
    try await script.executor.run(.activateLastApplication)
  }
  #expect(script.calls == ["lookup"])
}

@Test @MainActor
func propagatesApplicationOpenFailure() async {
  let script = ApplicationScript()
  script.openError = ApplicationScript.Failure.open

  await #expect(throws: ApplicationScript.Failure.open) {
    try await script.executor.run(.activateLastApplication)
  }
  #expect(script.calls == ["lookup", "open"])
}

@Test(arguments: [false, true]) @MainActor
func cancellationBeforeOrDuringLookupPreventsOpen(cancelDuringLookup: Bool) async {
  let script = ApplicationScript()
  script.cancelDuringLookup = cancelDuringLookup

  let task = Task { @MainActor in
    if !cancelDuringLookup { withUnsafeCurrentTask { $0?.cancel() } }
    return try await script.executor.run(.activateLastApplication)
  }

  await #expect(throws: CancellationError.self) { try await task.value }
  #expect(script.calls == (cancelDuringLookup ? ["lookup"] : []))
}
