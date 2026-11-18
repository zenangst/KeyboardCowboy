#if DEBUG
import CoreGraphics

extension MachPortSystem.KeyboardEventPoster {
  struct TestingOperations {
    let create: (CGEventSource?, CGKeyCode, Bool) -> CGEvent?
    let post: (CGEvent, CGEventTapLocation) -> Void
  }
}
#endif
