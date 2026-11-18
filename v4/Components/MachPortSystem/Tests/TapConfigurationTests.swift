import CoreFoundation
import CoreGraphics
import MachPortSystem
import Testing

@Test func tapConfigurationDefaultsAndCustomMask() {
  let configuration = MachPortSystem.TapConfiguration()
  let keyboardMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
    | (1 << CGEventType.keyUp.rawValue)
    | (1 << CGEventType.flagsChanged.rawValue)
  #expect(configuration.eventMask == keyboardMask)
  #expect(configuration.location == .cgSessionEventTap)
  #expect(configuration.placement == .headInsertEventTap)
  #expect(configuration.options == .defaultTap)
  #expect(configuration.sourceState == .privateState)
  #expect(configuration.runLoopMode == CFRunLoopMode.commonModes)

  let captureMask = keyboardMask | (1 << CGEventType.leftMouseDown.rawValue)
  let capture = MachPortSystem.TapConfiguration(eventMask: captureMask)
  #expect(capture.eventMask == captureMask)
}
