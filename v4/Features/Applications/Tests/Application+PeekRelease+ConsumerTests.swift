import UserSpace
import Commands
import ApplicationsFeature
import CowboyCore
import Foundation
import Testing

private actor ReleaseRecorder {
  private(set) var identifiers: [String] = []
  func record(_ identifier: String) { identifiers.append(identifier) }
}

@Test @MainActor func consumerCanResolvePeekRelease() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"peek","meta":{"id":"saved-command","name":"Peek","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let recorder = ReleaseRecorder()
  let executor = Application.Executor(.production, peekRelease: { received in
    await recorder.record(received.application.bundleIdentifier)
    return .none
  })

  let result = try await executor.execute(command, cgEventType: .keyUp, snapshot: snapshot)
  #expect(result === snapshot)
  #expect(await recorder.identifiers == ["example.target"])
}
