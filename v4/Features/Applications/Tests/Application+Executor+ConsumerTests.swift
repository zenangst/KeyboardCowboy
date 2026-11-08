import Commands
import AppKit
import ApplicationsFeature
import CowboyCore
import Foundation
import Testing

@Test @MainActor func applicationExecutorPublicAPI() async throws {
  let identifier = Core.BundleIdentifier("com.example.editor")
  let application = UserSpace.Application(
    bundleIdentifier: identifier,
    runningApplication: Core.RunningApplication(.production(.current)))
  let snapshot = UserSpace.Snapshot(apps: .init(frontMost: application, previous: application))
  #expect(snapshot.apps.frontMost?.bundleIdentifier == identifier)
  #expect(snapshot.apps.previous?.bundleIdentifier == identifier)

  let fixture = #"{"application":{"bundleIdentifier":"com.example.editor","bundleName":"Editor","path":"/Applications/Editor.app"},"action":"peek","meta":{"id":"saved-command","name":"Peek","enabled":true}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  try await Application.Executor(.production, windowOwnerNames: { [] }, willExecute: { _ in },
                                 selfApplication: .init(bundleIdentifier: .init("com.example.host"), open: {}),
                                 sleep: { _ in })
    .execute(command, cgEventType: nil, snapshot: snapshot)
}
