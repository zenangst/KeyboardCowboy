import Carbon
import Cocoa

enum MachPortError: Error {
  case failedToCreateMacPort
}

@MainActor
class MachPortEventPublisher {
  @Published var event: MachPortEvent?

  required init() throws {}
}

final class MachPortController: MachPortEventPublisher {
  private var eventSource: CGEventSource!
  private var machPort: CFMachPort!
  private var runLoopSource: CFRunLoopSource!

  public var isEnabled: Bool {
    get { machPort.map(CGEvent.tapIsEnabled) ?? false }
    set { machPort.map { CGEvent.tapEnable(tap: $0, enable: newValue) } }
  }

  required init() throws {
    try super.init()
    let machPort = try createMachPort()

    self.eventSource = try CGEventSource.create(.privateState)
    self.machPort = machPort
    self.runLoopSource = try CFRunLoopSource.create(with: machPort)
  }

  private func callback(_ proxy: CGEventTapProxy, _ type: CGEventType,
                        _ cgEvent: CGEvent) -> Unmanaged<CGEvent>? {
    let result: Unmanaged<CGEvent>? = Unmanaged.passUnretained(cgEvent)
    let newEvent = MachPortEvent(event: cgEvent, eventSource: eventSource,
                                 type: type, result: result)

    event = newEvent

    return newEvent.result
  }

  // MARK: Private methods

  private func createMachPort() throws -> CFMachPort {
    let tap: CGEventTapLocation = .cgSessionEventTap
    let place: CGEventTapPlacement = .headInsertEventTap
    let options: CGEventTapOptions = .defaultTap
    let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue
      | 1 << CGEventType.keyUp.rawValue
    let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

    // Taps placed at `kCGHIDEventTap', `kCGSessionEventTap',
    // `kCGAnnotatedSessionEventTap', or on a specific process may only receive
    // key up and down events if access for assistive devices is enabled
    // (Preferences Accessibility panel, Keyboard view) or the caller is enabled
    // for assistive device access, as by `AXMakeProcessTrusted'. If the tap is
    // not permitted to monitor these events when the tap is created, then the
    // appropriate bits in the mask are cleared. If that results in an empty
    // mask, then NULL is returned.
    guard let machPort = CGEvent.tapCreate(
      tap: tap,
      place: place,
      options: options,
      eventsOfInterest: mask,
      callback: { proxy, type, event, userInfo in
        if let pointer = userInfo {
          let controller = Unmanaged<MachPortController>
            .fromOpaque(pointer)
            .takeUnretainedValue()
          return controller.callback(proxy, type, event)
        }
        return Unmanaged.passUnretained(event)
      }, userInfo: userInfo) else {
      throw MachPortError.failedToCreateMacPort
    }

    return machPort
  }
}
