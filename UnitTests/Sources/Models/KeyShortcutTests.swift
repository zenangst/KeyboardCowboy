@testable import Keyboard_Cowboy
import XCTest

final class KeyShortcutTests: XCTestCase {

  func testModifersDisplayValue() {
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.shift]).modifersDisplayValue, "⇧")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.function]).modifersDisplayValue, "ƒ")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.control]).modifersDisplayValue, "⌃")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.option]).modifersDisplayValue, "⌥")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.command]).modifersDisplayValue, "⌘")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: ModifierKey.allCases).modifersDisplayValue, "ƒ⇧⌃⌥⌘")
  }

  func testValidationValue() {
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.shift]).validationValue, "⇧A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.function]).validationValue, "ƒA")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.control]).validationValue, "⌃A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.option]).validationValue, "⌥A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.command]).validationValue, "⌘A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: ModifierKey.allCases).validationValue, "ƒ⇧⌃⌥⌘A")
  }

  func testStringValue() {
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.shift]).stringValue, "$A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.function]).stringValue, "fnA")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.control]).stringValue, "^A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.option]).stringValue, "~A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.command]).stringValue, "@A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: ModifierKey.allCases).stringValue, "~fn^@$A")
  }

  func testFromDecoder_Key_Data() throws {
    let decoder = JSONDecoder()
    let data = """
    {
      "key": "A"
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertFalse(shortcut.id.isEmpty)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertTrue(shortcut.lhs)
    XCTAssertTrue(shortcut.modifiers.isEmpty)
  }

  func testFromDecoder_ID_Key_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A"
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertTrue(shortcut.lhs)
    XCTAssertTrue(shortcut.modifiers.isEmpty)
  }

  func testFromDecoder_ID_Key_LHS_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "lhs": false
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertFalse(shortcut.lhs)
    XCTAssertTrue(shortcut.modifiers.isEmpty)
  }

  func testFromDecoder_ID_Key_LHS_Modifier_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "lhs": false,
      "modifiers": ["$"]
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertFalse(shortcut.lhs)
    XCTAssertEqual(shortcut.modifiers, [.shift])
  }

  func testFromDecoder_ID_Key_LHS_Modifiers_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "lhs": false,
      "modifiers": ["fn", "$", "^", "~", "@"]
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertFalse(shortcut.lhs)
    XCTAssertEqual(shortcut.modifiers, ModifierKey.allCases)
  }

  func testEmptyMethod() {
    let id = UUID().uuidString
    let shortcut = KeyShortcut.empty(id: id)

    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "")
    XCTAssertTrue(shortcut.lhs)
    XCTAssertTrue(shortcut.modifiers.isEmpty)
  }
}
