import Commands
import Foundation
import Testing

@Test func applicationCommandSavedFixtureRoundTripsAndCopies() throws {
  let fixture = #"{"application":{"bundleIdentifier":"com.example.editor","bundleName":"Editor","displayName":"Custom Editor","path":"/Applications/Editor.app"},"action":"peek","modifiers":["waitForAppToLaunch","onlyIfNotRunning","hidden","background","addToStage"],"meta":{"id":"saved-command","name":"Editor","enabled":false,"delay":0.5,"notification":"capsule","variableName":"result"}}"#
  let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  #expect(command.action == .peek)
  #expect(command.application.displayName == "Custom Editor")
  #expect(command.modifiers == [.background, .hidden, .onlyIfNotRunning, .waitForAppToLaunch])
  #expect(command.meta.id == "saved-command")
  #expect(command.meta.isEnabled == false)
  #expect(command.meta.delay == 0.5)
  #expect(command.meta.notification == .capsule)
  #expect(command.meta.variableName == "result")

  let encoded = try JSONEncoder().encode(command)
  let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
  let application = try #require(object["application"] as? [String: Any])
  #expect(application["displayName"] as? String == "Custom Editor")
  #expect(object["modifiers"] as? [String] == ["background", "hidden", "onlyIfNotRunning", "waitForAppToLaunch"])
  #expect(try JSONDecoder().decode(Command.Application.self, from: encoded) == command)

  let copy = command.copy()
  #expect(copy.id != command.id)
  var expected = command
  expected.id = copy.id
  #expect(copy == expected)
}

@Test func retiredStageModifierMigratesWithoutMaskingUnknownValues() throws {
  let template = #"{"application":{"bundleIdentifier":"com.example.editor","bundleName":"Editor","path":"/Applications/Editor.app"},"action":"open","modifiers":MODIFIERS,"meta":{"id":"saved-command","name":"Editor","enabled":true}}"#
  for modifiers in [#"["addToStage"]"#, #"["addToStage","addToStage"]"#] {
    let fixture = template.replacingOccurrences(of: "MODIFIERS", with: modifiers)
    let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
    #expect(command.modifiers.isEmpty)
    let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(command)) as? [String: Any])
    #expect(object["modifiers"] == nil)
  }
  let nullFixture = template.replacingOccurrences(of: "MODIFIERS", with: "null")
  let nullCommand = try JSONDecoder().decode(Command.Application.self, from: Data(nullFixture.utf8))
  #expect(nullCommand.modifiers.isEmpty)
  for modifiers in [#"["addToStage","unknown"]"#, #"["addToStage",42]"#] {
    let fixture = template.replacingOccurrences(of: "MODIFIERS", with: modifiers)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
    }
  }
  #expect(!Command.Application.Modifier.allCases.map(\.rawValue).contains("addToStage"))
}

@Test func applicationCommandPreservesActionRawValuesAndMissingModifiers() throws {
  for rawValue in ["open", "close", "hide", "unhide", "peek"] {
    let fixture = #"{"application":{"bundleIdentifier":"com.example.editor","bundleName":"Editor","path":"/Applications/Editor.app"},"action":"\#(rawValue)","meta":{"id":"saved-command","name":"Editor","enabled":true}}"#
    let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
    #expect(command.action.rawValue == rawValue)
    #expect(command.modifiers.isEmpty)
    let encoded = try JSONEncoder().encode(command)
    let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    #expect(object["action"] as? String == rawValue)
    #expect(object["modifiers"] == nil)
    #expect(try JSONDecoder().decode(Command.Application.self, from: encoded) == command)
  }
}
