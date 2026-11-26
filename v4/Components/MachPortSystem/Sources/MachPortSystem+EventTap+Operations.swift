import CoreFoundation
import CoreGraphics

extension MachPortSystem.EventTap {
  static func callbackResult(_ result: CGEvent?, original: CGEvent) -> Unmanaged<CGEvent>? {
    guard let result else { return nil }

    return result === original ? .passUnretained(result) : .passRetained(result)
  }

  struct Operations {
    let start: (MachPortSystem.TapConfiguration, CFRunLoop, Context) -> Handle?
    let stop: (Handle, CFRunLoop, CFRunLoopMode) -> Void
    let isEnabled: (Handle) -> Bool

    init<Value>(
      start: @escaping (MachPortSystem.TapConfiguration, CFRunLoop, Context) -> Value?,
      stop: @escaping (Value, CFRunLoop, CFRunLoopMode) -> Void,
      isEnabled: @escaping (Value) -> Bool = { _ in true },
    ) {
      self.start = { configuration, loop, context in
        start(configuration, loop, context).map {
          Handle($0, stop: stop, isEnabled: isEnabled)
        }
      }
      self.stop = { handle, loop, mode in handle.stop(loop, mode) }
      self.isEnabled = { handle in handle.isEnabled() }
    }

    static var live: Self {
      .init(start: { configuration, loop, context -> LiveHandle? in
        let pointer = Unmanaged.passUnretained(context).toOpaque()
        guard let port = CGEvent.tapCreate(
          tap: configuration.location, place: configuration.placement,
          options: configuration.options, eventsOfInterest: configuration.eventMask,
          callback: { _, type, event, info in
            guard let info else { return Unmanaged.passUnretained(event) }

            let context = Unmanaged<Context>.fromOpaque(info).takeUnretainedValue()
            return callbackResult(context.deliver(type: type, event: event), original: event)
          }, userInfo: pointer,
        ) else { return nil }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
          CFMachPortInvalidate(port)
          return nil
        }

        let handle = LiveHandle(port: port, source: source, context: context)
        CFRunLoopAddSource(loop, source, configuration.runLoopMode)
        CGEvent.tapEnable(tap: port, enable: true)
        return handle
      }, stop: { handle, loop, mode in
        CGEvent.tapEnable(tap: handle.port, enable: false)
        CFRunLoopRemoveSource(loop, handle.source, mode)
        CFMachPortInvalidate(handle.port)
      }, isEnabled: { handle in
        CGEvent.tapIsEnabled(tap: handle.port)
      })
    }
  }

  private final class LiveHandle {
    let port: CFMachPort
    let source: CFRunLoopSource
    let context: Context
    init(port: CFMachPort, source: CFRunLoopSource, context: Context) {
      self.port = port
      self.source = source
      self.context = context
    }
  }
}
