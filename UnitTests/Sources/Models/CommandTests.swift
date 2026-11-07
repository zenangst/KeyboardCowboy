@testable import Keyboard_Cowboy
import XCTest

final class CommandTests: XCTestCase {
  func testShortcutCommandPersistenceFixtures() throws {
    let fixtures: [(String, String)] = [
      ("ordinary", "My Shortcut"),
      ("unicode", "日本語 ✨"),
      ("spaces", "  shortcut with spaces  "),
      ("empty", ""),
      ("id-like", "A7E8-1234"),
    ]

    for (label, identifier) in fixtures {
      let fixture: [String: Any] = ["runShortcut": [
        "shortcutIdentifier": identifier,
        "meta": ["id": "command-id", "name": "Saved name", "enabled": false,
                 "delay": 1.5, "notification": "bezel", "variableName": "result"],
      ]]
      let data = try JSONSerialization.data(withJSONObject: fixture)
      let command = try JSONDecoder().decode(Command.self, from: data)
      guard case let .shortcut(shortcut) = command else {
        XCTFail("Expected runShortcut for \(label)")
        continue
      }
      XCTAssertEqual(shortcut.shortcutIdentifier, identifier, label)
      XCTAssertEqual(shortcut.meta.id, "command-id", label)
      XCTAssertEqual(shortcut.meta.name, "Saved name", label)
      XCTAssertFalse(shortcut.meta.isEnabled, label)
      XCTAssertEqual(shortcut.meta.delay, 1.5, label)
      XCTAssertEqual(shortcut.meta.notification, .bezel, label)
      XCTAssertEqual(shortcut.meta.variableName, "result", label)

      let encoded = try JSONEncoder().encode(command)
      let actual = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
      XCTAssertEqual(actual, fixture as NSDictionary, label)
      XCTAssertEqual(try JSONDecoder().decode(Command.self, from: encoded), command, label)

      guard case let .shortcut(copy) = command.copy() else {
        XCTFail("Expected shortcut copy for \(label)")
        continue
      }
      XCTAssertEqual(copy.shortcutIdentifier, identifier, label)
      XCTAssertNotEqual(copy.meta.id, shortcut.meta.id, label)
      var expectedMeta = shortcut.meta
      expectedMeta.id = copy.meta.id
      XCTAssertEqual(copy.meta, expectedMeta, label)
    }
  }

  func testCopy() {
    let subject = Command.application(.init(name: "Test", action: .open, application: .calendar(), modifiers: [.onlyIfNotRunning], notification: .bezel))
    let copy = subject.copy()

    XCTAssertNotEqual(subject.id, copy.id)
    XCTAssertEqual(subject.name, copy.name)
    XCTAssertEqual(subject.notification, copy.notification)

    XCTAssertNotEqual(subject.meta.id, copy.meta.id)
    XCTAssertEqual(subject.meta.name, copy.meta.name)
    XCTAssertEqual(subject.meta.delay, copy.meta.delay)
    XCTAssertEqual(subject.meta.isEnabled, copy.meta.isEnabled)
    XCTAssertEqual(subject.meta.notification, copy.meta.notification)
  }
}
