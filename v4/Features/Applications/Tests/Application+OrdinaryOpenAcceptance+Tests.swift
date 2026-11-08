import Commands
@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

private func ordinaryAcceptanceCommand() throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"ordinary-acceptance","name":"Open","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

@Test(arguments: ["unavailable", "empty", "matching"])
@MainActor func ordinaryFrontmostOwnerAvailabilityControlsReopen(route: String) async throws {
  let target = Core.RunningApplication(.testing(.init("example.target")))
  let (events, continuation) = AsyncStream<String>.makeStream()
  let availableOwners: @Sendable () async -> [String] = {
    continuation.yield("owners")
    return route == "matching" ? ["Target"] : []
  }
  let owners = route == "unavailable" ? nil : availableOwners
  let executor = Application.Executor(.testing, windowOwnerNames: owners)
  let initial = UserSpace.Snapshot(apps: .init())

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: target, openApplication: { _, _ in
    continuation.yield("reopen")
    return target
  })) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { _, _ in continuation.yield("activate"); return true },
      runningApplications: [target]
    )) {
      try await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        continuation.yield("fallback")
        return nil
      })) {
        let result = try await executor.execute(try ordinaryAcceptanceCommand(), cgEventType: nil, snapshot: initial)
        #expect(result !== initial)
        #expect(result.apps.frontMost?.runningApplication === target)
      }
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  let expected = route == "unavailable" ? ["activate"] :
    route == "empty" ? ["owners", "activate", "fallback"] : ["owners", "activate", "reopen"]
  #expect(recorded == expected)
}

@Test @MainActor func cancellationDuringOrdinaryOwnerLookupPreventsOpenEffects() async throws {
  let command = try ordinaryAcceptanceCommand()
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
        Issue.record("Cancelled owner lookup must prevent launch")
        return .init(.testing(nil))
      })) {
        await Core.RunningApplication.Testing.$mock.withValue(.init(runningApplicationsLookup: { _ in
          Issue.record("Cancelled owner lookup must prevent application lookup")
          return []
        })) {
          do {
            _ = try await Application.Executor(.testing, windowOwnerNames: {
              withUnsafeCurrentTask { $0?.cancel() }
              return []
            }).execute(command, cgEventType: nil, snapshot: .init(apps: .init()))
            return false
          } catch is CancellationError {
            return true
          } catch {
            Issue.record("Unexpected error: \(error)")
            return false
          }
        }
      }
    }
    return await group.next() ?? false
  }
  #expect(cancelled)
}
