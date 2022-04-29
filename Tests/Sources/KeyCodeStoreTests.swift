import XCTest
import Carbon
@testable import Keyboard_Cowboy

final class KeyCodeStoreTests: XCTestCase {
  enum InputSourceIdentifier: String {
    case abc = "com.apple.keylayout.ABC"
    case english = "com.apple.keylayout.US"
    case swedish = "com.apple.keylayout.Swedish-Pro"
    case norwegian = "com.apple.keylayout.Norwegian"
  }

  var currentInput: InputSource?

  override func setUp() {
    super.setUp()
    currentInput = InputSourceController().currentInputSource()
  }

  override func tearDown() {
    super.tearDown()
    guard let currentInput = currentInput else { return }
    InputSourceController().selectInputSource(id: currentInput.id)
  }

  func testMapperWithABCLayout() throws {
    let inputController = InputSourceController()
    let id = InputSourceIdentifier.abc.rawValue

    let isInstalledABCKeyboard = inputController.isInstalledInputSource(id: id)
    inputController.installInputSource(id: id)
    defer {
      if isInstalledABCKeyboard == false {
        inputController.uninstallInputSource(id: id)
      }
    }

    guard let inputSource = inputController.selectInputSource(id: id) else {
      XCTFail("Failed to select input source")
      return
    }

    let keyCodeStore = KeyCodeStore(controller: inputController)

    XCTAssertEqual("\\", try keyCodeStore.mapInputSource(inputSource, keyCode: 42, modifiers: 0).displayValue)
    XCTAssertEqual("-", try keyCodeStore.mapInputSource(inputSource, keyCode: 27, modifiers: 0).displayValue)
    XCTAssertEqual(",", try keyCodeStore.mapInputSource(inputSource, keyCode: 43, modifiers: 0).displayValue)
    XCTAssertEqual("/", try keyCodeStore.mapInputSource(inputSource, keyCode: 44, modifiers: 0).displayValue)
    XCTAssertEqual(".", try keyCodeStore.mapInputSource(inputSource, keyCode: 47, modifiers: 0).displayValue)
    XCTAssertEqual("0", try keyCodeStore.mapInputSource(inputSource, keyCode: 29, modifiers: 0).displayValue)
    XCTAssertEqual("1", try keyCodeStore.mapInputSource(inputSource, keyCode: 18, modifiers: 0).displayValue)
    XCTAssertEqual("2", try keyCodeStore.mapInputSource(inputSource, keyCode: 19, modifiers: 0).displayValue)
    XCTAssertEqual("3", try keyCodeStore.mapInputSource(inputSource, keyCode: 20, modifiers: 0).displayValue)
    XCTAssertEqual("4", try keyCodeStore.mapInputSource(inputSource, keyCode: 21, modifiers: 0).displayValue)
    XCTAssertEqual("5", try keyCodeStore.mapInputSource(inputSource, keyCode: 23, modifiers: 0).displayValue)
    XCTAssertEqual("6", try keyCodeStore.mapInputSource(inputSource, keyCode: 22, modifiers: 0).displayValue)
    XCTAssertEqual("7", try keyCodeStore.mapInputSource(inputSource, keyCode: 26, modifiers: 0).displayValue)
    XCTAssertEqual("8", try keyCodeStore.mapInputSource(inputSource, keyCode: 28, modifiers: 0).displayValue)
    XCTAssertEqual("9", try keyCodeStore.mapInputSource(inputSource, keyCode: 25, modifiers: 0).displayValue)
    XCTAssertEqual("`", try keyCodeStore.mapInputSource(inputSource, keyCode: 50, modifiers: 0).displayValue)
    XCTAssertEqual("A", try keyCodeStore.mapInputSource(inputSource, keyCode: 0, modifiers: 0).displayValue)
    XCTAssertEqual("B", try keyCodeStore.mapInputSource(inputSource, keyCode: 11, modifiers: 0).displayValue)
    XCTAssertEqual("C", try keyCodeStore.mapInputSource(inputSource, keyCode: 8, modifiers: 0).displayValue)
    XCTAssertEqual("D", try keyCodeStore.mapInputSource(inputSource, keyCode: 2, modifiers: 0).displayValue)
    XCTAssertEqual("E", try keyCodeStore.mapInputSource(inputSource, keyCode: 14, modifiers: 0).displayValue)
    XCTAssertEqual("F", try keyCodeStore.mapInputSource(inputSource, keyCode: 3, modifiers: 0).displayValue)
    XCTAssertEqual("G", try keyCodeStore.mapInputSource(inputSource, keyCode: 5, modifiers: 0).displayValue)
    XCTAssertEqual("H", try keyCodeStore.mapInputSource(inputSource, keyCode: 4, modifiers: 0).displayValue)
    XCTAssertEqual("I", try keyCodeStore.mapInputSource(inputSource, keyCode: 34, modifiers: 0).displayValue)
    XCTAssertEqual("J", try keyCodeStore.mapInputSource(inputSource, keyCode: 38, modifiers: 0).displayValue)
    XCTAssertEqual("K", try keyCodeStore.mapInputSource(inputSource, keyCode: 40, modifiers: 0).displayValue)
    XCTAssertEqual("L", try keyCodeStore.mapInputSource(inputSource, keyCode: 37, modifiers: 0).displayValue)
    XCTAssertEqual("M", try keyCodeStore.mapInputSource(inputSource, keyCode: 46, modifiers: 0).displayValue)
    XCTAssertEqual("N", try keyCodeStore.mapInputSource(inputSource, keyCode: 45, modifiers: 0).displayValue)
    XCTAssertEqual("O", try keyCodeStore.mapInputSource(inputSource, keyCode: 31, modifiers: 0).displayValue)
    XCTAssertEqual("P", try keyCodeStore.mapInputSource(inputSource, keyCode: 35, modifiers: 0).displayValue)
    XCTAssertEqual("Q", try keyCodeStore.mapInputSource(inputSource, keyCode: 12, modifiers: 0).displayValue)
    XCTAssertEqual("R", try keyCodeStore.mapInputSource(inputSource, keyCode: 15, modifiers: 0).displayValue)
    XCTAssertEqual("S", try keyCodeStore.mapInputSource(inputSource, keyCode: 1, modifiers: 0).displayValue)
    XCTAssertEqual("T", try keyCodeStore.mapInputSource(inputSource, keyCode: 17, modifiers: 0).displayValue)
    XCTAssertEqual("U", try keyCodeStore.mapInputSource(inputSource, keyCode: 32, modifiers: 0).displayValue)
    XCTAssertEqual("V", try keyCodeStore.mapInputSource(inputSource, keyCode: 9, modifiers: 0).displayValue)
    XCTAssertEqual("W", try keyCodeStore.mapInputSource(inputSource, keyCode: 13, modifiers: 0).displayValue)
    XCTAssertEqual("X", try keyCodeStore.mapInputSource(inputSource, keyCode: 7, modifiers: 0).displayValue)
    XCTAssertEqual("Y", try keyCodeStore.mapInputSource(inputSource, keyCode: 16, modifiers: 0).displayValue)
    XCTAssertEqual("Z", try keyCodeStore.mapInputSource(inputSource, keyCode: 6, modifiers: 0).displayValue)
    XCTAssertEqual("§", try keyCodeStore.mapInputSource(inputSource, keyCode: 10, modifiers: 0).displayValue)
    XCTAssertEqual("]", try keyCodeStore.mapInputSource(inputSource, keyCode: 30, modifiers: 0).displayValue)
    XCTAssertEqual("=", try keyCodeStore.mapInputSource(inputSource, keyCode: 24, modifiers: 0).displayValue)
    XCTAssertEqual("'", try keyCodeStore.mapInputSource(inputSource, keyCode: 39, modifiers: 0).displayValue)
    XCTAssertEqual("[", try keyCodeStore.mapInputSource(inputSource, keyCode: 33, modifiers: 0).displayValue)
    XCTAssertEqual(";", try keyCodeStore.mapInputSource(inputSource, keyCode: 41, modifiers: 0).displayValue)
  }

  // swiftlint:disable function_body_length
  func testMapperWithSwedishLayout() throws {
    let inputController = InputSourceController()
    let id = InputSourceIdentifier.swedish.rawValue
    let isInstalledABCKeyboard = inputController.isInstalledInputSource(id: id)
    inputController.installInputSource(id: id)
    defer {
      if isInstalledABCKeyboard == false {
        inputController.uninstallInputSource(id: id)
      }
    }

    guard let inputSource = inputController.selectInputSource(id: id) else {
      XCTFail("Failed to select input source")
      return
    }

    let keyCodeStore = KeyCodeStore(controller: inputController)
    XCTAssertEqual("'", try keyCodeStore.mapInputSource(inputSource, keyCode: 42, modifiers: 0).displayValue)
    XCTAssertEqual("+", try keyCodeStore.mapInputSource(inputSource, keyCode: 27, modifiers: 0).displayValue)
    XCTAssertEqual(",", try keyCodeStore.mapInputSource(inputSource, keyCode: 43, modifiers: 0).displayValue)
    XCTAssertEqual("-", try keyCodeStore.mapInputSource(inputSource, keyCode: 44, modifiers: 0).displayValue)
    XCTAssertEqual(".", try keyCodeStore.mapInputSource(inputSource, keyCode: 47, modifiers: 0).displayValue)
    XCTAssertEqual("0", try keyCodeStore.mapInputSource(inputSource, keyCode: 29, modifiers: 0).displayValue)
    XCTAssertEqual("1", try keyCodeStore.mapInputSource(inputSource, keyCode: 18, modifiers: 0).displayValue)
    XCTAssertEqual("2", try keyCodeStore.mapInputSource(inputSource, keyCode: 19, modifiers: 0).displayValue)
    XCTAssertEqual("3", try keyCodeStore.mapInputSource(inputSource, keyCode: 20, modifiers: 0).displayValue)
    XCTAssertEqual("4", try keyCodeStore.mapInputSource(inputSource, keyCode: 21, modifiers: 0).displayValue)
    XCTAssertEqual("5", try keyCodeStore.mapInputSource(inputSource, keyCode: 23, modifiers: 0).displayValue)
    XCTAssertEqual("6", try keyCodeStore.mapInputSource(inputSource, keyCode: 22, modifiers: 0).displayValue)
    XCTAssertEqual("7", try keyCodeStore.mapInputSource(inputSource, keyCode: 26, modifiers: 0).displayValue)
    XCTAssertEqual("8", try keyCodeStore.mapInputSource(inputSource, keyCode: 28, modifiers: 0).displayValue)
    XCTAssertEqual("9", try keyCodeStore.mapInputSource(inputSource, keyCode: 25, modifiers: 0).displayValue)
    XCTAssertEqual("<", try keyCodeStore.mapInputSource(inputSource, keyCode: 50, modifiers: 0).displayValue)
    XCTAssertEqual("A", try keyCodeStore.mapInputSource(inputSource, keyCode: 0, modifiers: 0).displayValue)
    XCTAssertEqual("B", try keyCodeStore.mapInputSource(inputSource, keyCode: 11, modifiers: 0).displayValue)
    XCTAssertEqual("C", try keyCodeStore.mapInputSource(inputSource, keyCode: 8, modifiers: 0).displayValue)
    XCTAssertEqual("D", try keyCodeStore.mapInputSource(inputSource, keyCode: 2, modifiers: 0).displayValue)
    XCTAssertEqual("E", try keyCodeStore.mapInputSource(inputSource, keyCode: 14, modifiers: 0).displayValue)
    XCTAssertEqual("F", try keyCodeStore.mapInputSource(inputSource, keyCode: 3, modifiers: 0).displayValue)
    XCTAssertEqual("G", try keyCodeStore.mapInputSource(inputSource, keyCode: 5, modifiers: 0).displayValue)
    XCTAssertEqual("H", try keyCodeStore.mapInputSource(inputSource, keyCode: 4, modifiers: 0).displayValue)
    XCTAssertEqual("I", try keyCodeStore.mapInputSource(inputSource, keyCode: 34, modifiers: 0).displayValue)
    XCTAssertEqual("J", try keyCodeStore.mapInputSource(inputSource, keyCode: 38, modifiers: 0).displayValue)
    XCTAssertEqual("K", try keyCodeStore.mapInputSource(inputSource, keyCode: 40, modifiers: 0).displayValue)
    XCTAssertEqual("L", try keyCodeStore.mapInputSource(inputSource, keyCode: 37, modifiers: 0).displayValue)
    XCTAssertEqual("M", try keyCodeStore.mapInputSource(inputSource, keyCode: 46, modifiers: 0).displayValue)
    XCTAssertEqual("N", try keyCodeStore.mapInputSource(inputSource, keyCode: 45, modifiers: 0).displayValue)
    XCTAssertEqual("O", try keyCodeStore.mapInputSource(inputSource, keyCode: 31, modifiers: 0).displayValue)
    XCTAssertEqual("P", try keyCodeStore.mapInputSource(inputSource, keyCode: 35, modifiers: 0).displayValue)
    XCTAssertEqual("Q", try keyCodeStore.mapInputSource(inputSource, keyCode: 12, modifiers: 0).displayValue)
    XCTAssertEqual("R", try keyCodeStore.mapInputSource(inputSource, keyCode: 15, modifiers: 0).displayValue)
    XCTAssertEqual("S", try keyCodeStore.mapInputSource(inputSource, keyCode: 1, modifiers: 0).displayValue)
    XCTAssertEqual("T", try keyCodeStore.mapInputSource(inputSource, keyCode: 17, modifiers: 0).displayValue)
    XCTAssertEqual("U", try keyCodeStore.mapInputSource(inputSource, keyCode: 32, modifiers: 0).displayValue)
    XCTAssertEqual("V", try keyCodeStore.mapInputSource(inputSource, keyCode: 9, modifiers: 0).displayValue)
    XCTAssertEqual("W", try keyCodeStore.mapInputSource(inputSource, keyCode: 13, modifiers: 0).displayValue)
    XCTAssertEqual("X", try keyCodeStore.mapInputSource(inputSource, keyCode: 7, modifiers: 0).displayValue)
    XCTAssertEqual("Y", try keyCodeStore.mapInputSource(inputSource, keyCode: 16, modifiers: 0).displayValue)
    XCTAssertEqual("Z", try keyCodeStore.mapInputSource(inputSource, keyCode: 6, modifiers: 0).displayValue)
    XCTAssertEqual("§", try keyCodeStore.mapInputSource(inputSource, keyCode: 10, modifiers: 0).displayValue)
    XCTAssertEqual("¨", try keyCodeStore.mapInputSource(inputSource, keyCode: 30, modifiers: 0).displayValue)
    XCTAssertEqual("´", try keyCodeStore.mapInputSource(inputSource, keyCode: 24, modifiers: 0).displayValue)
    XCTAssertEqual("Ä", try keyCodeStore.mapInputSource(inputSource, keyCode: 39, modifiers: 0).displayValue)
    XCTAssertEqual("Å", try keyCodeStore.mapInputSource(inputSource, keyCode: 33, modifiers: 0).displayValue)
    XCTAssertEqual("Ö", try keyCodeStore.mapInputSource(inputSource, keyCode: 41, modifiers: 0).displayValue)
  }

  // swiftlint:disable function_body_length
  func testMapperWithNorwegianLayout() throws {
    let inputController = InputSourceController()
    let id = InputSourceIdentifier.norwegian.rawValue
    let isInstalledABCKeyboard = inputController.isInstalledInputSource(id: id)
    inputController.installInputSource(id: id)
    defer {
      if isInstalledABCKeyboard == false {
        inputController.uninstallInputSource(id: id)
      }
    }

    guard let inputSource = inputController.selectInputSource(id: id) else {
      XCTFail("Failed to select input source")
      return
    }

    let keyCodeStore = KeyCodeStore(controller: inputController)
    XCTAssertEqual("@", try keyCodeStore.mapInputSource(inputSource, keyCode: 42, modifiers: 0).displayValue)
    XCTAssertEqual("+", try keyCodeStore.mapInputSource(inputSource, keyCode: 27, modifiers: 0).displayValue)
    XCTAssertEqual(",", try keyCodeStore.mapInputSource(inputSource, keyCode: 43, modifiers: 0).displayValue)
    XCTAssertEqual("-", try keyCodeStore.mapInputSource(inputSource, keyCode: 44, modifiers: 0).displayValue)
    XCTAssertEqual(".", try keyCodeStore.mapInputSource(inputSource, keyCode: 47, modifiers: 0).displayValue)
    XCTAssertEqual("0", try keyCodeStore.mapInputSource(inputSource, keyCode: 29, modifiers: 0).displayValue)
    XCTAssertEqual("1", try keyCodeStore.mapInputSource(inputSource, keyCode: 18, modifiers: 0).displayValue)
    XCTAssertEqual("2", try keyCodeStore.mapInputSource(inputSource, keyCode: 19, modifiers: 0).displayValue)
    XCTAssertEqual("3", try keyCodeStore.mapInputSource(inputSource, keyCode: 20, modifiers: 0).displayValue)
    XCTAssertEqual("4", try keyCodeStore.mapInputSource(inputSource, keyCode: 21, modifiers: 0).displayValue)
    XCTAssertEqual("5", try keyCodeStore.mapInputSource(inputSource, keyCode: 23, modifiers: 0).displayValue)
    XCTAssertEqual("6", try keyCodeStore.mapInputSource(inputSource, keyCode: 22, modifiers: 0).displayValue)
    XCTAssertEqual("7", try keyCodeStore.mapInputSource(inputSource, keyCode: 26, modifiers: 0).displayValue)
    XCTAssertEqual("8", try keyCodeStore.mapInputSource(inputSource, keyCode: 28, modifiers: 0).displayValue)
    XCTAssertEqual("9", try keyCodeStore.mapInputSource(inputSource, keyCode: 25, modifiers: 0).displayValue)
    XCTAssertEqual("<", try keyCodeStore.mapInputSource(inputSource, keyCode: 50, modifiers: 0).displayValue)
    XCTAssertEqual("A", try keyCodeStore.mapInputSource(inputSource, keyCode: 0, modifiers: 0).displayValue)
    XCTAssertEqual("B", try keyCodeStore.mapInputSource(inputSource, keyCode: 11, modifiers: 0).displayValue)
    XCTAssertEqual("C", try keyCodeStore.mapInputSource(inputSource, keyCode: 8, modifiers: 0).displayValue)
    XCTAssertEqual("D", try keyCodeStore.mapInputSource(inputSource, keyCode: 2, modifiers: 0).displayValue)
    XCTAssertEqual("E", try keyCodeStore.mapInputSource(inputSource, keyCode: 14, modifiers: 0).displayValue)
    XCTAssertEqual("F", try keyCodeStore.mapInputSource(inputSource, keyCode: 3, modifiers: 0).displayValue)
    XCTAssertEqual("G", try keyCodeStore.mapInputSource(inputSource, keyCode: 5, modifiers: 0).displayValue)
    XCTAssertEqual("H", try keyCodeStore.mapInputSource(inputSource, keyCode: 4, modifiers: 0).displayValue)
    XCTAssertEqual("I", try keyCodeStore.mapInputSource(inputSource, keyCode: 34, modifiers: 0).displayValue)
    XCTAssertEqual("J", try keyCodeStore.mapInputSource(inputSource, keyCode: 38, modifiers: 0).displayValue)
    XCTAssertEqual("K", try keyCodeStore.mapInputSource(inputSource, keyCode: 40, modifiers: 0).displayValue)
    XCTAssertEqual("L", try keyCodeStore.mapInputSource(inputSource, keyCode: 37, modifiers: 0).displayValue)
    XCTAssertEqual("M", try keyCodeStore.mapInputSource(inputSource, keyCode: 46, modifiers: 0).displayValue)
    XCTAssertEqual("N", try keyCodeStore.mapInputSource(inputSource, keyCode: 45, modifiers: 0).displayValue)
    XCTAssertEqual("O", try keyCodeStore.mapInputSource(inputSource, keyCode: 31, modifiers: 0).displayValue)
    XCTAssertEqual("P", try keyCodeStore.mapInputSource(inputSource, keyCode: 35, modifiers: 0).displayValue)
    XCTAssertEqual("Q", try keyCodeStore.mapInputSource(inputSource, keyCode: 12, modifiers: 0).displayValue)
    XCTAssertEqual("R", try keyCodeStore.mapInputSource(inputSource, keyCode: 15, modifiers: 0).displayValue)
    XCTAssertEqual("S", try keyCodeStore.mapInputSource(inputSource, keyCode: 1, modifiers: 0).displayValue)
    XCTAssertEqual("T", try keyCodeStore.mapInputSource(inputSource, keyCode: 17, modifiers: 0).displayValue)
    XCTAssertEqual("U", try keyCodeStore.mapInputSource(inputSource, keyCode: 32, modifiers: 0).displayValue)
    XCTAssertEqual("V", try keyCodeStore.mapInputSource(inputSource, keyCode: 9, modifiers: 0).displayValue)
    XCTAssertEqual("W", try keyCodeStore.mapInputSource(inputSource, keyCode: 13, modifiers: 0).displayValue)
    XCTAssertEqual("X", try keyCodeStore.mapInputSource(inputSource, keyCode: 7, modifiers: 0).displayValue)
    XCTAssertEqual("Y", try keyCodeStore.mapInputSource(inputSource, keyCode: 16, modifiers: 0).displayValue)
    XCTAssertEqual("Z", try keyCodeStore.mapInputSource(inputSource, keyCode: 6, modifiers: 0).displayValue)
    XCTAssertEqual("'", try keyCodeStore.mapInputSource(inputSource, keyCode: 10, modifiers: 0).displayValue)
    XCTAssertEqual("¨", try keyCodeStore.mapInputSource(inputSource, keyCode: 30, modifiers: 0).displayValue)
    XCTAssertEqual("´", try keyCodeStore.mapInputSource(inputSource, keyCode: 24, modifiers: 0).displayValue)
    XCTAssertEqual("Æ", try keyCodeStore.mapInputSource(inputSource, keyCode: 39, modifiers: 0).displayValue)
    XCTAssertEqual("Å", try keyCodeStore.mapInputSource(inputSource, keyCode: 33, modifiers: 0).displayValue)
    XCTAssertEqual("Ø", try keyCodeStore.mapInputSource(inputSource, keyCode: 41, modifiers: 0).displayValue)
  }

  func testMapperMappingFKeys() throws {
    let inputController = InputSourceController()
    let inputSource = inputController.currentInputSource()
    let keyCodeStore = KeyCodeStore(controller: inputController)
    XCTAssertEqual("F1", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F1, modifiers: 0).displayValue)
    XCTAssertEqual("F2", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F2, modifiers: 0).displayValue)
    XCTAssertEqual("F3", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F3, modifiers: 0).displayValue)
    XCTAssertEqual("F4", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F4, modifiers: 0).displayValue)
    XCTAssertEqual("F5", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F5, modifiers: 0).displayValue)
    XCTAssertEqual("F6", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F6, modifiers: 0).displayValue)
    XCTAssertEqual("F7", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F7, modifiers: 0).displayValue)
    XCTAssertEqual("F8", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F8, modifiers: 0).displayValue)
    XCTAssertEqual("F9", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F9, modifiers: 0).displayValue)
    XCTAssertEqual("F10", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F10, modifiers: 0).displayValue)
    XCTAssertEqual("F11", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F11, modifiers: 0).displayValue)
    XCTAssertEqual("F12", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F12, modifiers: 0).displayValue)
    XCTAssertEqual("F13", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F13, modifiers: 0).displayValue)
    XCTAssertEqual("F14", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F14, modifiers: 0).displayValue)
    XCTAssertEqual("F15", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F15, modifiers: 0).displayValue)
    XCTAssertEqual("F16", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F16, modifiers: 0).displayValue)
    XCTAssertEqual("F17", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F17, modifiers: 0).displayValue)
    XCTAssertEqual("F18", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F18, modifiers: 0).displayValue)
    XCTAssertEqual("F19", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F19, modifiers: 0).displayValue)
    XCTAssertEqual("F20", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_F20, modifiers: 0).displayValue)
  }

  func testMapperMappingSpecialKeys() throws {
    let inputController = InputSourceController()
    let inputSource = inputController.currentInputSource()
    let keyCodeStore = KeyCodeStore(controller: inputController)
    XCTAssertEqual("Space", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_Space, modifiers: 0).displayValue)
    XCTAssertEqual("⌫", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_Delete, modifiers: 0).displayValue)
    XCTAssertEqual("⌦", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_ForwardDelete, modifiers: 0).displayValue)
    XCTAssertEqual("⌧", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_ANSI_Keypad0, modifiers: 0).displayValue)
    XCTAssertEqual("←", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_LeftArrow, modifiers: 0).displayValue)
    XCTAssertEqual("→", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_RightArrow, modifiers: 0).displayValue)
    XCTAssertEqual("↑", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_UpArrow, modifiers: 0).displayValue)
    XCTAssertEqual("↓", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_DownArrow, modifiers: 0).displayValue)
    XCTAssertEqual("↘", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_End, modifiers: 0).displayValue)
    XCTAssertEqual("↖", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_Home, modifiers: 0).displayValue)
    XCTAssertEqual("⎋", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_Escape, modifiers: 0).displayValue)
    XCTAssertEqual("⇟", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_PageDown, modifiers: 0).displayValue)
    XCTAssertEqual("⇞", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_PageUp, modifiers: 0).displayValue)
    XCTAssertEqual("↩", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_Return, modifiers: 0).displayValue)
    XCTAssertEqual("⌅", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_ANSI_KeypadEnter, modifiers: 0).displayValue)
    XCTAssertEqual("⇥", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_Tab, modifiers: 0).displayValue)
    XCTAssertEqual("?⃝", try keyCodeStore.mapInputSource(inputSource, keyCode: kVK_Help, modifiers: 0).displayValue)
  }
}
