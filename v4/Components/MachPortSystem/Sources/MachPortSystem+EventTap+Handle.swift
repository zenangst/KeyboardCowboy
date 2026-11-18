import CoreFoundation

extension MachPortSystem.EventTap {
  final class Handle {
    let stop: (CFRunLoop, CFRunLoopMode) -> Void
    let isEnabled: () -> Bool

    init<Value>(
      _ value: Value,
      stop: @escaping (Value, CFRunLoop, CFRunLoopMode) -> Void,
      isEnabled: @escaping (Value) -> Bool,
    ) {
      self.stop = { loop, mode in stop(value, loop, mode) }
      self.isEnabled = { isEnabled(value) }
    }
  }
}
