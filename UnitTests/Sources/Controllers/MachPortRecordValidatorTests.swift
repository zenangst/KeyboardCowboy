import XCTest
import InputSources
@testable import MachPort
@testable import Keyboard_Cowboy

@MainActor
final class MachPortRecordValidatorTests: XCTestCase {
  func testValidatorMapping_LeftCommand_S() {
    let validator = MachPortRecordValidator(store: KeyCodesStore(InputSourceController()))
    switch validator.validate(createEvent(1, modifiers: [.leftCommand])) {
    case .valid(let shortcut):
      XCTAssertEqual(shortcut.key, "s")
      XCTAssertEqual(shortcut.modifiers, [.leftCommand])
    default:
      XCTFail("Failed to return a valid shortcut")
    }
  }

  func testValidatorMapping_RightCommand_S() {
    let validator = MachPortRecordValidator(store: KeyCodesStore(InputSourceController()))
    switch validator.validate(createEvent(1, modifiers: [.rightCommand])) {
    case .valid(let shortcut):
      XCTAssertEqual(shortcut.key, "s")
      XCTAssertEqual(shortcut.modifiers, [.rightCommand])
    default:
      XCTFail("Failed to return a valid shortcut")
    }
  }

  func testValidatorMapping_LeftAndRightCommand_S() {
    let validator = MachPortRecordValidator(store: KeyCodesStore(InputSourceController()))
    switch validator.validate(createEvent(1, modifiers: [.leftCommand, .rightCommand])) {
    case .valid(let shortcut):
      XCTAssertEqual(shortcut.key, "s")
      XCTAssertEqual(shortcut.modifiers, [.leftCommand, .rightCommand])
    default:
      XCTFail("Failed to return a valid shortcut")
    }
  }

  private func createEvent(_ keyCode: Float16, modifiers: [ModifierKey]) -> MachPortEvent {
    let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(exactly: keyCode)!, keyDown: true)!
    event.flags = modifiers.reduce(into: CGEventFlags.maskNonCoalesced, { partialResult, key in
      partialResult.insert(key.cgEventFlags)
    })

    return MachPortEvent(
      id: UUID(),
      event: event,
      eventSource: nil,
      isRepeat: false,
      type: .keyDown,
      result: nil
    )
  }
}
