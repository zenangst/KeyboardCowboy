import ApplicationsFeature
import CowboyCore
import Foundation
import Testing

@Test @MainActor func consumerCanSupplyStageAdapter() async throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Applications/Target.app"},"action":"peek","meta":{"id":"saved-command","name":"Peek","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let executor = Application.Executor(.production, addToStage: { _ in false })
  let result = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
  #expect(result === snapshot)
}
