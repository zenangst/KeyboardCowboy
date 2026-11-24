import Commands
import Foundation
import Testing

private struct MenuBarEnvelope: Codable {
  let menuBarCommand: Command.MenuBar
}

@Test func menuBarPayloadRoundTripsLegacyApplicationMetadataAndTokens() throws {
  let fixture = #"""
  {
    "menuBarCommand": {
      "application": {
        "bundleIdentifier": "com.example.editor",
        "bundleName": "Editor",
        "displayName": "My Editor",
        "path": "/Applications/My Editor.app"
      },
      "meta": {
        "id": "menu-id", "name": "Fill window", "enabled": false,
        "delay": 1.25, "notification": "capsule", "variableName": "output"
      },
      "tokens": [
        {"menuItem": {"name": "Window"}},
        {"menuItems": {"name": "Fill", "fallbackName": "Zoom"}}
      ]
    }
  }
  """#
  let data = Data(fixture.utf8)
  let envelope = try JSONDecoder().decode(MenuBarEnvelope.self, from: data)
  let command = envelope.menuBarCommand
  #expect(command.tokens == [.menuItem(name: "Window"), .menuItems(name: "Fill", fallbackName: "Zoom")])
  #expect(command.application?.bundleIdentifier == "com.example.editor")
  #expect(command.application?.bundleName == "Editor")
  #expect(command.application?.displayName == "My Editor")
  #expect(command.application?.path == "/Applications/My Editor.app")
  #expect(command.meta == .init(delay: 1.25, id: "menu-id", name: "Fill window",
                               isEnabled: false, notification: .capsule, variableName: "output"))

  let copy = command.copy()
  #expect(copy.id != command.id)
  var copyWithOriginalID = copy
  copyWithOriginalID.id = command.id
  #expect(copyWithOriginalID == command)
  try expectSameJSON(try JSONEncoder().encode(envelope), data)
}

@Test func menuBarPayloadPreservesAbsentApplicationAndEmptyTokens() throws {
  let data = Data(#"{"menuBarCommand":{"meta":{"id":"menu-id","name":"","enabled":true},"tokens":[]}}"#.utf8)
  let envelope = try JSONDecoder().decode(MenuBarEnvelope.self, from: data)
  #expect(envelope.menuBarCommand.application == nil)
  #expect(envelope.menuBarCommand.tokens.isEmpty)
  try expectSameJSON(try JSONEncoder().encode(envelope), data)
}

private func expectSameJSON(_ actual: Data, _ expected: Data) throws {
  let actualObject = try #require(JSONSerialization.jsonObject(with: actual) as? NSDictionary)
  let expectedObject = try #require(JSONSerialization.jsonObject(with: expected) as? NSDictionary)
  #expect(actualObject == expectedObject)
}
