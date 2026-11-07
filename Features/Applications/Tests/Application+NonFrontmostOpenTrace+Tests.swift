@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

@Test(arguments: ["unavailable", "matching", "other", "missing", "no-frontmost"])
@MainActor func nonFrontmostOrdinaryOpenOrdersLaunchLookupAndBestEffortActivation(route: String) async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let frontmost = Core.RunningApplication(.testing(.init("example.frontmost")))
  let launched = Core.RunningApplication(.testing(.init("example.launched")))
  let target = Core.RunningApplication(.testing(identifier))
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"open","meta":{"id":"trace","name":"Open","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let initial = UserSpace.Snapshot(apps: .init())
  let (events, continuation) = AsyncStream<String>.makeStream()
  let availableOwners: @Sendable () async -> [String] = {
    continuation.yield("owners")
    return route == "matching" ? ["Target"] : ["Other"]
  }
  let executor = Application.Executor(.testing, windowOwnerNames: route == "unavailable" ? nil : availableOwners)

  try await Core.Workspace.Testing.$mock.withValue(.init(
    frontmostApplication: route == "no-frontmost" ? nil : frontmost,
    openApplication: { url, configuration in
      #expect(url.path() == "/Applications/Target.app")
      #expect(configuration.activates)
      continuation.yield("launch")
      return launched
    }
  )) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      activateFrom: { from, options in
        #expect(from === frontmost)
        #expect(options == (route == "matching" ? [] : [.activateAllWindows]))
        continuation.yield("activate-from")
        return false
      },
      runningApplicationsLookup: { requested in
        #expect(requested == identifier)
        continuation.yield("lookup")
        return route == "missing" ? [] : [target]
      },
      onActivate: { application, options in
        #expect(application === target)
        #expect(options == [.activateAllWindows])
        continuation.yield("activate")
        return false
      }
    )) {
      try await Core.NSAppleScript.Testing.$mock.withValue(.init(execute: {
        Issue.record("Non-frontmost activation rejection must not invoke fallback")
        return nil
      })) {
        let result = try await executor.execute(command, cgEventType: nil, snapshot: initial)
        #expect(result !== initial)
        #expect(result.apps.frontMost?.runningApplication === (route == "no-frontmost" ? nil : frontmost))
      }
    }
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  let expected: [String]
  switch route {
  case "unavailable": expected = ["launch"]
  case "missing": expected = ["owners", "launch", "lookup"]
  case "no-frontmost": expected = ["owners", "launch", "lookup", "activate"]
  default: expected = ["owners", "launch", "lookup", "activate-from"]
  }
  #expect(recorded == expected)
}
