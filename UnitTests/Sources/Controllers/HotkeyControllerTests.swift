@testable import LogicFramework
import XCTest

class HotkeyControllerTests: XCTestCase {
  let notificationCenter = NotificationControllerMock()
  // Add a random opaque pointer to check that the handler
  // gets invoked when a hotkey has a reference. The value is irrelavant
  // for the tests.
  let randomReference = OpaquePointer(bitPattern: 8)

  func testHotkeyControllerWithRegisterAndUnregister() {
    let installHandlerExpectation = self.expectation(description: "Wait for installation")
    let registerExpectation = self.expectation(description: "Wait for registering hotkey")
    let unregisterExpectation = self.expectation(description: "Wait for unregistering hotkey")
    let hotkey = Hotkey(keyboardShortcut: .init(key: "A"), keyCode: 0)
    hotkey.reference = randomReference

    let hotkeyHandler = HotkeyHandlerMock(registerResult: true) { state in
      switch state {
      case .installHandler:
        installHandlerExpectation.fulfill()
      case .register(let registeredHotkey, let signature):
        XCTAssertEqual(hotkey, registeredHotkey)
        XCTAssertEqual("HotkeyHandlerMock", signature)
        registerExpectation.fulfill()
      case .sendKeyboardEvent:
        break
      case .unregister:
        unregisterExpectation.fulfill()
      }
    }
    let controller = HotkeyController(
      hotkeyHandler: hotkeyHandler,
      notificationCenter: notificationCenter)

    XCTAssertEqual(controller.hotkeys.count, 0)

    controller.register(hotkey)
    XCTAssertEqual(controller.hotkeys.count, 1)

    controller.unregister(hotkey)
    XCTAssertEqual(controller.hotkeys.count, 0)

    let expectations = [
      installHandlerExpectation,
      registerExpectation,
      unregisterExpectation
    ]
    wait(for: expectations, timeout: 10.0, enforceOrder: true)
  }

  func testHotkeyControllerWithRegisterAndUnregisterAll() {
    let installHandlerExpectation = self.expectation(description: "Wait for installation")
    let registerExpectation = self.expectation(description: "Wait for registering hotkey")
    let unregisterExpectation = self.expectation(description: "Wait for unregistering hotkey")
    let hotkey = Hotkey(keyboardShortcut: .init(key: "A"), keyCode: 0)
    hotkey.reference = randomReference

    let hotkeyHandler = HotkeyHandlerMock(registerResult: true) { state in
      switch state {
      case .installHandler:
        installHandlerExpectation.fulfill()
      case .register(let registeredHotkey, let signature):
        XCTAssertEqual(hotkey, registeredHotkey)
        XCTAssertEqual("HotkeyHandlerMock", signature)
        registerExpectation.fulfill()
      case .sendKeyboardEvent:
        break
      case .unregister:
        unregisterExpectation.fulfill()
      }
    }
    let controller = HotkeyController(
      hotkeyHandler: hotkeyHandler,
      notificationCenter: notificationCenter)

    XCTAssertEqual(controller.hotkeys.count, 0)

    controller.register(hotkey)
    XCTAssertEqual(controller.hotkeys.count, 1)

    controller.unregisterAll()
    XCTAssertEqual(controller.hotkeys.count, 0)

    let expectations = [
      installHandlerExpectation,
      registerExpectation,
      unregisterExpectation
    ]
    wait(for: expectations, timeout: 10.0, enforceOrder: true)
  }

  func testHotkeyControllerWithRegisterAndUnregisterWithApplicationWillTerminate() {
    let installHandlerExpectation = self.expectation(description: "Wait for installation")
    let registerExpectation = self.expectation(description: "Wait for registering hotkey")
    let unregisterExpectation = self.expectation(description: "Wait for unregistering hotkey")
    let hotkey = Hotkey(keyboardShortcut: .init(key: "A"), keyCode: 0)
    hotkey.reference = randomReference

    let hotkeyHandler = HotkeyHandlerMock(registerResult: true) { state in
      switch state {
      case .installHandler:
        installHandlerExpectation.fulfill()
      case .register(let registeredHotkey, let signature):
        XCTAssertEqual(hotkey, registeredHotkey)
        XCTAssertEqual("HotkeyHandlerMock", signature)
        registerExpectation.fulfill()
      case .sendKeyboardEvent:
        break
      case .unregister:
        unregisterExpectation.fulfill()
      }
    }
    let controller = HotkeyController(
      hotkeyHandler: hotkeyHandler,
      notificationCenter: notificationCenter)

    XCTAssertEqual(controller.hotkeys.count, 0)

    controller.register(hotkey)
    XCTAssertEqual(controller.hotkeys.count, 1)

    controller.applicationWillTerminate()
    XCTAssertEqual(controller.hotkeys.count, 0)

    let expectations = [
      installHandlerExpectation,
      registerExpectation,
      unregisterExpectation
    ]
    wait(for: expectations, timeout: 10.0, enforceOrder: true)
  }
}
