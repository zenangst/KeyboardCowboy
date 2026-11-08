import Commands
@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

@Test @MainActor func hostSessionRoutesOnlyLongPeekReleases() async throws {
  let peekFixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"peek","meta":{"id":"peek","name":"Peek","enabled":true}}"#
  let previousFixture = #"{"application":{"bundleIdentifier":"example.previous","bundleName":"Previous","path":"/Applications/Previous.app"},"action":"open","meta":{"id":"previous","name":"Previous","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(peekFixture.utf8))
  let previous = try JSONDecoder().decode(Command.Application.self, from: Data(previousFixture.utf8))

  // A host chooses normal hiding, previous-app restoration, or no-op from its settings/history.
  for mode in 0...3 {
    let session = Application.PeekSession()
    let sessionID = UUID()
    let target = Core.RunningApplication(.testing(.init("example.target")))
    let snapshot = UserSpace.Snapshot(apps: .init())
    let (events, continuation) = AsyncStream<String>.makeStream()
    let executor = Application.Executor(.testing, peekRelease: { _ in
      continuation.yield("release")
      switch mode {
      case 0, 1: return .hide
      case 2: return .open(previous)
      default: return .none
      }
    })

    #expect(await session.begin(id: sessionID, at: .zero))
    try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { url, _ in
      continuation.yield(url.lastPathComponent)
      return .init(.testing(nil))
    })) {
      try await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplications: [target], onHide: { application in
          #expect(application === target)
          continuation.yield("hide")
          return true
        }
      )) {
        do {
          _ = try await executor.execute(command, cgEventType: .keyDown, snapshot: snapshot)
        } catch {
          await session.cancel(id: sessionID)
          throw error
        }
        let duration: Duration = mode == 0 ? .milliseconds(500) : .milliseconds(501)
        if await session.release(id: sessionID, at: duration) == .hold {
          _ = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
        }
      }
    }
    #expect(await session.release(id: sessionID, at: .seconds(1)) == .unrelated)
    continuation.finish()
    var recorded: [String] = []
    for await event in events { recorded.append(event) }
    let expected: [String] = switch mode {
    case 0: ["Target.app"]
    case 1: ["Target.app", "release", "hide"]
    case 2: ["Target.app", "release", "Previous.app"]
    default: ["Target.app", "release"]
    }
    #expect(recorded == expected)
  }
}
