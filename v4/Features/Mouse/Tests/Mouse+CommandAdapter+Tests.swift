import Commands
import Foundation
@testable import MouseFeature
import Testing

@Test(arguments: [
  (#"{"click":{"_0":{"focused":{"_0":{"center":{}}}}}}"#, Mouse.ClickKind.click, Mouse.Anchor.center),
  (#"{"doubleClick":{"_0":{"focused":{"_0":{"trailing":{}}}}}}"#, .doubleClick, .trailing),
  (#"{"rightClick":{"_0":{"focused":{"_0":{"custom":{"x":-12,"y":34}}}}}}"#, .rightClick, .custom(x: -12, y: 34)),
])
func legacyMousePayloadPreservesExecutionTarget(
  _ kindJSON: String, _ expectedKind: Mouse.ClickKind, _ expectedAnchor: Mouse.Anchor,
) throws {
  let data = Data("""
    {"kind":\(kindJSON),"meta":{"id":"mouse-fixture","name":"Test","enabled":false}}
    """.utf8)
  let decoder = JSONDecoder()
  let command = try decoder.decode(Command.Mouse.self, from: data)
  let (kind, anchor) = Mouse.executionTarget(for: command.kind)
  #expect(kind == expectedKind)
  #expect(anchor == expectedAnchor)
  #expect(!command.isEnabled)
  #expect(try decoder.decode(Command.Mouse.self, from: JSONEncoder().encode(command)) == command)
}
