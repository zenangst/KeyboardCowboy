import Carbon
import Cocoa

public struct HotKeyContext {
  let keyCode: Int64
  let event: CGEvent
  let eventSource: CGEventSource
  let type: CGEventType
  var result: Unmanaged<CGEvent>?
}

/// A rebinding controller is responsible for intercepting keyboard shortcuts and posting
/// alternate events when rebounded keys are invoked.
public protocol HotKeyControlling {
  var coreController: CoreControlling? { get set }
  var isEnabled: Bool { get set }
  func callback(_ proxy: CGEventTapProxy, _ type: CGEventType, _ cgEvent: CGEvent) -> Unmanaged<CGEvent>?
}

enum RebindingControllingError: Error {
  case unableToCreateMachPort
  case unableToCreateRunLoopSource
  case unableToCreateEventSource
}

final class HotKeyController: HotKeyControlling {
  private static var cache = [String: Int]()
  private var eventSource: CGEventSource!
  private var machPort: CFMachPort!
  private var runLoopSource: CFRunLoopSource!
  public weak var coreController: CoreControlling?

  var isEnabled: Bool {
    set { machPort.map { CGEvent.tapEnable(tap: $0, enable: newValue) } }
    get { machPort.map(CGEvent.tapIsEnabled) ?? false }
  }

  required init() throws {
    self.eventSource = try createEventSource()
    self.machPort = try createMachPort()
    self.runLoopSource = try createRunLoopSource()
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    Debug.print("⌨️")
  }

  func callback(_ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let result: Unmanaged<CGEvent>? = Unmanaged.passUnretained(event)
    var context = HotKeyContext(keyCode: keyCode, event: event,
                                eventSource: eventSource, type: type,
                                result: result)
    coreController?.receive(&context)
    return context.result
  }

  // MARK: Private methods

  private func createMachPort() throws -> CFMachPort? {
    Debug.print("⌨️")
    let tap: CGEventTapLocation = .cgSessionEventTap
    let place: CGEventTapPlacement = .headInsertEventTap
    let options: CGEventTapOptions = .defaultTap
    let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue
      | 1 << CGEventType.keyUp.rawValue
    guard let machPort = CGEvent.tapCreate(
            tap: tap,
            place: place,
            options: options,
            eventsOfInterest: mask,
            callback: { proxy, type, event, userInfo -> Unmanaged<CGEvent>? in
              if let pointer = userInfo {
                let controller = Unmanaged<HotKeyController>.fromOpaque(pointer).takeUnretainedValue()
                return controller.callback(proxy, type, event)
              }
              return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())) else {
      throw RebindingControllingError.unableToCreateMachPort
    }
    Debug.print("⌨️")
    return machPort
  }

  private func createRunLoopSource() throws -> CFRunLoopSource {
    Debug.print("⌨️")
    guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0) else {
      throw RebindingControllingError.unableToCreateRunLoopSource
    }
    Debug.print("⌨️")
    return runLoopSource
  }

  private func createEventSource() throws -> CGEventSource {
    Debug.print("⌨️")
    guard let eventSource = CGEventSource(stateID: .privateState) else {
      throw RebindingControllingError.unableToCreateEventSource
    }
    Debug.print("⌨️")
    return eventSource
  }
}
