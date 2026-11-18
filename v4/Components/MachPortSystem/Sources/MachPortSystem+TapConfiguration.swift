import CoreFoundation
import CoreGraphics

public extension MachPortSystem {
  /// Configuration for one event tap. The host owns permission and run-loop setup.
  struct TapConfiguration {
    public var location: CGEventTapLocation
    public var placement: CGEventTapPlacement
    public var options: CGEventTapOptions
    public var eventMask: CGEventMask
    public var sourceState: CGEventSourceStateID
    public var runLoopMode: CFRunLoopMode

    public static var keyboardEventMask: CGEventMask {
      (1 << CGEventType.keyDown.rawValue)
        | (1 << CGEventType.keyUp.rawValue)
        | (1 << CGEventType.flagsChanged.rawValue)
    }

    public init(
      location: CGEventTapLocation = .cgSessionEventTap,
      placement: CGEventTapPlacement = .headInsertEventTap,
      options: CGEventTapOptions = .defaultTap,
      eventMask: CGEventMask = TapConfiguration.keyboardEventMask,
      sourceState: CGEventSourceStateID = .privateState,
      runLoopMode: CFRunLoopMode = .commonModes,
    ) {
      self.location = location
      self.placement = placement
      self.options = options
      self.eventMask = eventMask
      self.sourceState = sourceState
      self.runLoopMode = runLoopMode
    }
  }
}
