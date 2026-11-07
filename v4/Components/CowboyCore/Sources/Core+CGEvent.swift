import CoreGraphics

public extension Core {
  struct CGEvent {
    public let keyCode: Int64
    public let type: CGEventType
    public let isRepeat: Bool

    public init(_ event: CoreGraphics::CGEvent) {
      self.keyCode = event.getIntegerValueField(.keyboardEventKeycode)
      self.type = event.type
      self.isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1
    }
  }
}
