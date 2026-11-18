#if DEBUG
import CoreGraphics

extension MachPortSystem.KeyboardEventPoster {
  struct TestingOperations {
    let create: (CGEventSource?, CGKeyCode, Bool) -> CGEvent?
    let createFlags: (CGEventSource?) -> CGEvent?
    let post: (CGEvent, CGEventTapLocation) -> Void

    init(
      create: @escaping (CGEventSource?, CGKeyCode, Bool) -> CGEvent?,
      createFlags: @escaping (CGEventSource?) -> CGEvent? = { CGEvent(source: $0) },
      post: @escaping (CGEvent, CGEventTapLocation) -> Void,
    ) {
      self.create = create
      self.createFlags = createFlags
      self.post = post
    }
  }
}
#endif
