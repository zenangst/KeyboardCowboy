import Foundation
import Testing
import TextFeature

@Test func legacyTextEnvelopeRoundTripsMetadataAndActions() throws {
  let json = #"{"textCommand":{"kind":{"insertText":{"_0":{"input":"Hello $name","mode":"Typing","actions":["insertEnter"],"meta":{"delay":0.5,"id":"abc","name":"Example","enabled":false,"notification":"commandPanel","variableName":"result"}}}}}}"#
  let decoded = try JSONDecoder().decode(TextCommandEnvelope.self, from: Data(json.utf8))
  guard case let .insertText(command) = decoded.textCommand.kind else { Issue.record("Unexpected command"); return }
  #expect(command.input == "Hello $name")
  #expect(command.mode == .typing)
  #expect(command.actions == [.insertEnter])
  #expect(command.meta == TextCommandMetadata(delay: 0.5, id: "abc", name: "Example", isEnabled: false, notification: .commandPanel, variableName: "result"))
  #expect(command.execution(resolvedInput: "Hello Ada") == TextExecution(input: "Hello Ada", mode: .typing, actions: [.insertEnter]))

  let encoded = try JSONEncoder().encode(decoded)
  let originalObject = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? NSDictionary
  let encodedObject = try JSONSerialization.jsonObject(with: encoded) as? NSDictionary
  #expect(encodedObject == originalObject)
}

@Test func legacyDefaultsAndInstantEncoding() throws {
  let json = #"{"textCommand":{"kind":{"insertText":{"_0":{"input":"x","meta":{"id":"id","name":"","enabled":true,"notification":"unknown"}}}}}}"#
  let decoded = try JSONDecoder().decode(TextCommandEnvelope.self, from: Data(json.utf8))
  guard case let .insertText(command) = decoded.textCommand.kind else { Issue.record("Unexpected command"); return }
  #expect(command.mode == .instant)
  #expect(command.actions.isEmpty)
  #expect(command.meta.notification == nil)
  let encoded = try JSONEncoder().encode(decoded)
  let expected = #"{"textCommand":{"kind":{"insertText":{"_0":{"input":"x","mode":"Instant","actions":[],"meta":{"id":"id","name":"","enabled":true}}}}}}"#
  #expect(try JSONSerialization.jsonObject(with: encoded) as? NSDictionary == JSONSerialization.jsonObject(with: Data(expected.utf8)) as? NSDictionary)
}
