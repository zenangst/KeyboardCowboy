import CowboyCore
import Foundation
import Testing

@Test func applicationCommandRoundTripsEachModifierAndNotification() throws {
  for modifier in Command.Application.Modifier.allCases {
    for notification in Command.Notification.allCases {
      let fixture = #"{"application":{"bundleIdentifier":"example.editor","bundleName":"Editor","path":"/Applications/Editor.app"},"action":"open","modifiers":["\#(modifier.rawValue)"],"meta":{"id":"saved","name":"Editor","enabled":true,"delay":0.25,"notification":"\#(notification.rawValue)","variableName":"result"}}"#
      let command = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
      #expect(command.modifiers == [modifier])
      #expect(command.meta.notification == notification)
      #expect(command.meta.delay == 0.25)
      #expect(command.meta.variableName == "result")
      #expect(try JSONDecoder().decode(Command.Application.self, from: JSONEncoder().encode(command)) == command)
      var expected = command
      let copy = command.copy()
      #expect(copy.id != command.id)
      expected.id = copy.id
      #expect(copy == expected)
    }
  }
}

@Test func applicationCommandNormalizesDuplicateModifiersAndCopiesIndependently() throws {
  let fixture = #"{"application":{"bundleIdentifier":"com.example.editor","bundleName":"Editor","path":"/Applications/Editor.app"},"action":"open","modifiers":["hidden","background","hidden","addToStage","background"],"meta":{"id":"original","name":"Editor","enabled":true}}"#
  let original = try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
  #expect(original.modifiers == [.background, .hidden])

  let encoded = try JSONEncoder().encode(original)
  let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
  #expect(object["modifiers"] as? [String] == ["background", "hidden"])
  #expect(try JSONDecoder().decode(Command.Application.self, from: encoded) == original)

  var copy = original.copy()
  #expect(copy.id != original.id)
  var expected = original
  expected.id = copy.id
  #expect(copy == expected)
  copy.modifiers.remove(.hidden)
  copy.meta.name = "Changed copy"
  #expect(original.modifiers == [.background, .hidden])
  #expect(original.meta.name == "Editor")
}

@Test func applicationCommandRejectsMalformedRequiredFieldsAndModifierContainers() throws {
  let validApplication = #"{"bundleIdentifier":"com.example.editor","bundleName":"Editor","path":"/Applications/Editor.app"}"#
  let validMeta = #"{"id":"saved","name":"Editor","enabled":true}"#
  let fixtures = [
    #"{"action":"open","meta":\#(validMeta)}"#,
    #"{"application":null,"action":"open","meta":\#(validMeta)}"#,
    #"{"application":\#(validApplication),"meta":\#(validMeta)}"#,
    #"{"application":\#(validApplication),"action":"unknown","meta":\#(validMeta)}"#,
    #"{"application":\#(validApplication),"action":42,"meta":\#(validMeta)}"#,
    #"{"application":\#(validApplication),"action":"open"}"#,
    #"{"application":\#(validApplication),"action":"open","meta":{}}"#,
    #"{"application":\#(validApplication),"action":"open","modifiers":"hidden","meta":\#(validMeta)}"#,
    #"{"application":\#(validApplication),"action":"open","modifiers":{},"meta":\#(validMeta)}"#,
    #"{"application":\#(validApplication),"action":"open","modifiers":[null],"meta":\#(validMeta)}"#,
  ]
  for fixture in fixtures {
    #expect(throws: (any Error).self, "Accepted malformed fixture: \(fixture)") {
      try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
    }
  }
}
