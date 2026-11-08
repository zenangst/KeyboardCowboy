import Commands
import Foundation
import Testing

private struct OpenEnvelope: Codable {
  let openCommand: Command.Open
}

@Test func openPayloadRoundTripsLegacyEnvelope() throws {
  let fixture = #"""
  {"openCommand":{"application":{"bundleIdentifier":"com.example.browser","bundleName":"Browser","displayName":"My Browser","path":"/Applications/My Browser.app"},"path":"file:///tmp/a%20file","meta":{"id":"open-id","name":"Open file","enabled":false,"delay":1.25,"notification":"capsule","variableName":"output"}}}
  """#
  let command = try JSONDecoder().decode(OpenEnvelope.self, from: Data(fixture.utf8)).openCommand
  #expect(command.path == "file:///tmp/a%20file")
  #expect(command.application?.bundleIdentifier == "com.example.browser")
  #expect(command.application?.bundleName == "Browser")
  #expect(command.application?.displayName == "My Browser")
  #expect(command.application?.path == "/Applications/My Browser.app")
  #expect(command.meta.id == "open-id")
  #expect(command.meta.name == "Open file")
  #expect(!command.meta.isEnabled)
  #expect(command.meta.delay == 1.25)
  #expect(command.meta.notification == .capsule)
  #expect(command.meta.variableName == "output")
  let encoded = try JSONEncoder().encode(OpenEnvelope(openCommand: command))
  let decoded = try JSONDecoder().decode(OpenEnvelope.self, from: encoded).openCommand
  #expect(decoded == command)
  #expect(decoded.application?.displayName == "My Browser")
}

@Test func openPayloadSupportsAbsentApplicationAndLegacyNotificationFallback() throws {
  let data = Data(#"{"path":"~/Documents/a file","meta":{"id":"id","name":"","enabled":true,"notification":"unknown"}}"#.utf8)
  let command = try JSONDecoder().decode(Command.Open.self, from: data)
  #expect(command.application == nil)
  #expect(command.path == "~/Documents/a file")
  #expect(command.meta.notification == nil)
  let copy = command.copy()
  #expect(copy.meta.id != command.meta.id)
  #expect(copy.path == command.path)
  let constructed = Command.Open(path: "custom:value")
  #expect(constructed.application == nil)
  #expect(constructed.path == "custom:value")
}
