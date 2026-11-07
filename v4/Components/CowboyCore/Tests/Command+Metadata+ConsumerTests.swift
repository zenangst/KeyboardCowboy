import CowboyCore
import Foundation
import Testing

@Test func metadataConsumerRoundTripAndCopy() throws {
  let fixture = #"{"id":"saved-command-id","name":"Open editor","enabled":false,"delay":0.5,"notification":"capsule","variableName":"result"}"#
  let metadata = try JSONDecoder().decode(Command.Metadata.self, from: Data(fixture.utf8))

  #expect(metadata.id == "saved-command-id")
  #expect(metadata.name == "Open editor")
  #expect(metadata.isEnabled == false)
  #expect(metadata.delay == 0.5)
  #expect(metadata.notification == .capsule)
  #expect(metadata.variableName == "result")

  let encoded = try JSONEncoder().encode(metadata)
  let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
  #expect(json["enabled"] as? Bool == false)
  #expect(json["isEnabled"] == nil)
  #expect(try JSONDecoder().decode(Command.Metadata.self, from: encoded) == metadata)

  let copy = metadata.copy()
  #expect(copy.id != metadata.id)
  var expected = metadata
  expected.id = copy.id
  #expect(copy == expected)

  let constructed = Command.Metadata(delay: 0.5, id: "saved-command-id", name: "Open editor",
                                     isEnabled: false, notification: .capsule, variableName: "result")
  #expect(constructed == metadata)
}
