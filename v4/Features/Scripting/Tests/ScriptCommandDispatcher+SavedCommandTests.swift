import Commands
import Foundation
import ScriptingFeature
import Testing

private struct Envelope: Codable {
  let scriptCommand: Command.Script
}

@Test(arguments: [
  (#"{"appleScript":{"variant":{"regular":{}}}}"#, "inline", "apple-inline:saved:expanded"),
  (#"{"appleScript":{"variant":{"regular":{}}}}"#, "path", "apple-file:saved:/fixtures/<<value>>"),
  (#"{"appleScript":{"variant":{"jxa":{}}}}"#, "inline", "jxa:expanded"),
  (#"{"appleScript":{"variant":{"jxa":{}}}}"#, "path", "apple-file:saved:/fixtures/<<value>>"),
  (#"{"shellScript":{}}"#, "inline", "shell-inline:expanded"),
  (#"{"shellScript":{}}"#, "path", "shell-file:/fixtures/expanded"),
  (#""scpt""#, "inline", "apple-inline:saved:expanded"),
  (#""sh""#, "path", "shell-file:/fixtures/expanded"),
])
func savedScriptCommandPreservesMetadataAndRoutes(kind: String, source: String, expected: String) async throws {
  let contents = source == "path" ? "/fixtures/<<value>>" : "<<value>>"
  let fixture = """
    {"scriptCommand":{
      "kind":\(kind),"source":{"\(source)":{"_0":"\(contents)"}},
      "meta":{"id":"saved","name":"Saved script","enabled":false,"delay":125,
              "notification":"bezel","variableName":"SCRIPT_RESULT"}
    }}
    """
  let envelope = try JSONDecoder().decode(Envelope.self, from: Data(fixture.utf8))
  let command = envelope.scriptCommand
  #expect(command.meta == .init(delay: 125, id: "saved", name: "Saved script",
                                isEnabled: false, notification: .bezel, variableName: "SCRIPT_RESULT"))

  let encoded = try JSONEncoder().encode(envelope)
  let encodedEnvelope = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
  let encodedPayload = try #require(encodedEnvelope["scriptCommand"] as? [String: Any])
  #expect(encodedPayload["kind"] is [String: Any]) // Legacy kinds are saved in the modern shape.
  #expect(try JSONDecoder().decode(Envelope.self, from: encoded).scriptCommand == command)

  let dispatcher = ScriptCommandDispatcher(routes: .init(
    appleScriptInline: { "apple-inline:\($1):\($0)" },
    appleScriptFile: { "apple-file:\($1):\($0)" },
    jxaInline: { "jxa:\($0)" },
    shellInline: { "shell-inline:\($0)" },
    shellFile: { "shell-file:\($0)" },
    clearAppleScriptCache: { Issue.record("Unexpected cache clear") },
  ))
  let interpolation = ScriptInterpolation([.init(token: "<<value>>", value: "expanded")])
  #expect(try await dispatcher.execute(command, interpolation: interpolation) == expected)
}

@Test(arguments: [#""unknown""#, #"{"appleScript":{"variant":{"unsupported":{}}}}"#])
func savedScriptCommandRejectsUnknownKindOrVariant(kind: String) {
  let fixture = """
    {"scriptCommand":{
      "kind":\(kind),"source":{"inline":{"_0":"noop"}},
      "meta":{"id":"saved","name":"Saved script","enabled":true}
    }}
    """
  #expect(throws: DecodingError.self) {
    try JSONDecoder().decode(Envelope.self, from: Data(fixture.utf8))
  }
}
