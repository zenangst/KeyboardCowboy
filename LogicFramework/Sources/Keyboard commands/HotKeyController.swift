import Carbon
import Cocoa

/// A rebinding controller is responsible for intercepting keyboard shortcuts and posting
/// alternate events when rebounded keys are invoked.
public protocol HotKeyControlling {
  var delegate: HotKeyControllingDelegate? { get set }
  var isEnabled: Bool { get set }
  func callback(_ proxy: CGEventTapProxy, _ type: CGEventType, _ cgEvent: CGEvent) -> Unmanaged<CGEvent>?
}

public class HotKeyContext {
  let keyCode: Int64
  let event: CGEvent
  let eventSource: CGEventSource?
  let type: CGEventType
  var result: Unmanaged<CGEvent>?

  init(event: CGEvent,
       eventSource: CGEventSource?,
       type: CGEventType,
       result: Unmanaged<CGEvent>?) {
    self.keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    self.event = event
    self.eventSource = eventSource
    self.type = type
    self.result = result
  }
}

public protocol HotKeyControllingDelegate: AnyObject {
  func hotKeyController(_ controller: HotKeyControlling, didReceiveContext context: HotKeyContext)
}

enum HotKeyControllerError: Error {
  case unableToCreateMachPort
  case unableToCreateRunLoopSource
  case unableToCreateEventSource
}

final class HotKeyController: HotKeyControlling {
  public weak var delegate: HotKeyControllingDelegate?

  private var eventSource: CGEventSource!
  private var machPort: CFMachPort!
  private var runLoopSource: CFRunLoopSource!

  var isEnabled: Bool {
    get { machPort.map(CGEvent.tapIsEnabled) ?? false }
    set { machPort.map { CGEvent.tapEnable(tap: $0, enable: newValue) } }
  }

  required init() throws {
    self.eventSource = try createEventSource()
    self.machPort = try createMachPort()
    self.runLoopSource = try createRunLoopSource()
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
  }

  func callback(_ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
    let result: Unmanaged<CGEvent>? = Unmanaged.passUnretained(event)
    let context = HotKeyContext(event: event,
                                eventSource: eventSource,
                                type: type,
                                result: result)
    delegate?.hotKeyController(self, didReceiveContext: context)
    return context.result
  }

  // MARK: Private methods

  private func createMachPort() throws -> CFMachPort? {
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
      throw HotKeyControllerError.unableToCreateMachPort
    }
    Debug.print("⌨️")
    return machPort
  }

  private func createRunLoopSource() throws -> CFRunLoopSource {
    guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0) else {
      throw HotKeyControllerError.unableToCreateRunLoopSource
    }
    return runLoopSource
  }

  private func createEventSource() throws -> CGEventSource {
    guard let eventSource = CGEventSource(stateID: .privateState) else {
      throw HotKeyControllerError.unableToCreateEventSource
    }
    return eventSource
  }
}
