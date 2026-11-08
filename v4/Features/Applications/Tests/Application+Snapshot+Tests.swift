import Commands
@testable import ApplicationsFeature
@testable import CowboyCore
import CoreGraphics
import Foundation
import Testing

private actor SnapshotLaunchRecorder {
  private(set) var count = 0
  func record() { count += 1 }
}

@Test @MainActor func nonRefreshingActionsKeepOriginalSnapshot() async throws {
  let snapshot = UserSpace.Snapshot(apps: .init())
  let recorder = SnapshotLaunchRecorder()
  let cases: [(String, CGEventType?)] = [
    ("hide", nil), ("unhide", nil), ("peek", nil),
    ("peek", .keyUp), ("peek", .keyDown),
  ]

  try await Core.Workspace.Testing.$mock.withValue(.init(openApplication: { _, _ in
    await recorder.record()
    return .init(.testing(nil))
  })) {
    for (action, event) in cases {
      let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"\#(action)","meta":{"id":"saved-command","name":"Target","enabled":true}}"#
      let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
      let result = try await Application.Executor(.testing).execute(command, cgEventType: event, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
  #expect(await recorder.count == 1)
}
