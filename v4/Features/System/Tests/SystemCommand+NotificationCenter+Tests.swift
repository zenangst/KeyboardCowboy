import Foundation
import ScriptingFeature
@testable import SystemFeature
import Testing
import UserSpace

@MainActor
private func notificationExecutor(
  _ execute: @escaping @MainActor (ScriptRequest) async throws -> String?,
) -> SystemCommand.Executor {
  SystemCommand.Executor(
    sendDockNotification: { _ in Issue.record("Unexpected Dock notification") },
    previousApplication: {
      Issue.record("Unexpected app history lookup")
      return (nil, UserSpace.Snapshot(apps: .init()))
    },
    openApplication: { _, _, _ in Issue.record("Unexpected application open") },
    executeScript: execute,
  )
}

@Test @MainActor func notificationCenterRunsTheLegacyInlineAppleScript() async throws {
  let data = Data(#""showNotificationCenter""#.utf8)
  let action = try JSONDecoder().decode(SystemCommand.Action.self, from: data)
  var requests: [ScriptRequest] = []
  let executor = notificationExecutor {
    await Task.yield()
    requests.append($0)
    return "ignored"
  }

  #expect(try await executor.run(action) == .invoked)
  #expect(try JSONEncoder().encode(action) == data)
  let request = try #require(requests.first)
  #expect(requests.count == 1)
  #expect(request.id == "showNotificationCenter")
  guard case .appleScript(.regular) = request.kind, case .inline(let source) = request.source else {
    Issue.record("Expected regular inline AppleScript")
    return
  }
  #expect(source == """
    tell application "System Events"
    click menu bar item 2 of menu bar 1 of application process "ControlCenter"
    end tell
    """)
}

private enum ScriptFailure: Error {
  case denied
}

@Test @MainActor func notificationCenterPropagatesScriptFailure() async {
  let executor = notificationExecutor { _ in throw ScriptFailure.denied }
  await #expect(throws: ScriptFailure.denied) {
    try await executor.run(.showNotificationCenter)
  }
}

@Test @MainActor func notificationCenterDoesNotInvokeScriptsWhenPrecancelled() async {
  let executor = notificationExecutor { _ in
    Issue.record("Unexpected script execution")
    return nil
  }
  let task = Task { @MainActor in
    withUnsafeCurrentTask { $0?.cancel() }
    return try await executor.run(.showNotificationCenter)
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}
