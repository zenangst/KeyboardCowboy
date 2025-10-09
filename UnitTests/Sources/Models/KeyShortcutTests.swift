@testable import Keyboard_Cowboy
import XCTest

final class KeyShortcutTests: XCTestCase {
  func testModifersDisplayValue() {
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftShift]).modifersDisplayValue, "⇧")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.function]).modifersDisplayValue, "ƒ")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftControl]).modifersDisplayValue, "⌃")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftOption]).modifersDisplayValue, "⌥")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftCommand]).modifersDisplayValue, "⌘")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: ModifierKey.allCases).modifersDisplayValue, "ƒ⇧⇧⌃⌃⌥⌥⌘⌘⇪")
  }

  func testValidationValue() {
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftShift]).validationValue, "⇧A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.function]).validationValue, "ƒA")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftControl]).validationValue, "⌃A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftOption]).validationValue, "⌥A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftCommand]).validationValue, "⌘A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: ModifierKey.allCases).validationValue, "ƒ⇧⇧⌃⌃⌥⌥⌘⌘⇪A")
  }

  func testStringValue() {
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftShift]).stringValue, "$A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.function]).stringValue, "fnA")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftControl]).stringValue, "^A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftOption]).stringValue, "~A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: [.leftCommand]).stringValue, "@A")
    XCTAssertEqual(KeyShortcut(key: "A", modifiers: ModifierKey.allCases).stringValue, "⇪~r~r^r@r$fn^@$A")
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
    XCTAssertTrue(shortcut.modifiers.isEmpty)
  }

  func testFromDecoder_ID_Key_LHS_Modifier_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "modifiers": ["$"]
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertEqual(shortcut.modifiers, [.leftShift])
  }

  func testFromDecoder_ID_Key_RHS_Modifier_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "modifiers": ["r$"]
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertEqual(shortcut.modifiers, [.rightShift])
  }

  func testFromDecoder_ID_Key_AllLeftKeys_Modifiers_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "lhs": true,
      "modifiers": ["fn", "$", "^", "~", "@", "⇪"]
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertEqual(Set(shortcut.modifiers), Set(ModifierKey.leftModifiers + [.capsLock, .function]))
  }

  func testFromDecoder_ID_Key_AllRightKeys_Modifiers_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "modifiers": ["fn", "r$", "r^", "r~", "r@", "⇪"]
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertEqual(Set(shortcut.modifiers), Set(ModifierKey.rightModifiers + [.capsLock, .function]))
  }

  func testFromDecoder_ID_Key_AllKeys_Modifiers_Data() throws {
    let decoder = JSONDecoder()
    let id = UUID().uuidString
    let data = """
    {
      "id": "\(id)",
      "key": "A",
      "modifiers": ["fn", "r$", "$", "r^", "^", "r~", "~", "r@", "@", "⇪"]
    }
    """.data(using: .utf8)!

    let shortcut = try decoder.decode(KeyShortcut.self, from: data)
    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "A")
    XCTAssertEqual(Set(shortcut.modifiers), Set(ModifierKey.allCases))
  }

  func testEmptyMethod() {
    let id = UUID().uuidString
    let shortcut = KeyShortcut.empty(id: id)

    XCTAssertEqual(shortcut.id, id)
    XCTAssertEqual(shortcut.key, "")
    XCTAssertTrue(shortcut.modifiers.isEmpty)
  }
}
