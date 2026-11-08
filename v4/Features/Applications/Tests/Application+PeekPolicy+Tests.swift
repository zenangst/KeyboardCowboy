import Commands
import ApplicationsFeature
import CowboyCore
import Foundation
import Testing

@Test func peekReleasePolicyHandlesStageManagerAndHistory() throws {
  let fixture = #"{"application":{"bundleIdentifier":"example.previous","bundleName":"Previous","path":"/Applications/Previous.app"},"action":"hide","modifiers":["background","hidden","onlyIfNotRunning","waitForAppToLaunch"],"meta":{"id":"saved-command","name":"Old","enabled":false,"delay":2,"variableName":"result"}}"#
  let previous = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))

  guard case .hide = Application.Executor.PeekReleaseAction.resolve(stageManagerEnabled: false, previous: previous) else {
    Issue.record("Disabled Stage Manager must hide")
    return
  }
  guard case .hide = Application.Executor.PeekReleaseAction.resolve(stageManagerEnabled: false, previous: nil) else {
    Issue.record("Disabled Stage Manager must hide even without history")
    return
  }
  guard case .none = Application.Executor.PeekReleaseAction.resolve(stageManagerEnabled: true, previous: nil) else {
    Issue.record("Missing history must be a no-op")
    return
  }
  guard case .open(let command) = Application.Executor.PeekReleaseAction.resolve(stageManagerEnabled: true, previous: previous) else {
    Issue.record("Enabled Stage Manager must open the supplied previous application")
    return
  }
  #expect(command.application.bundleIdentifier == "example.previous")
  #expect(command.application.path == "/Applications/Previous.app")
  #expect(command.action == .open)
  #expect(command.modifiers.isEmpty)
  #expect(command.meta.id != previous.meta.id)
  #expect(command.meta.name.isEmpty)
  #expect(command.meta.isEnabled)
  #expect(command.meta.delay == nil)
  #expect(command.meta.variableName == nil)
}
