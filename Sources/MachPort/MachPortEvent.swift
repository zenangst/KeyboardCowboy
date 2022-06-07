import CoreGraphics
import Foundation

public final class MachPortEvent {
  public let keyCode: Int64
  public let event: CGEvent
  public let eventSource: CGEventSource?
  public let type: CGEventType
  public var result: Unmanaged<CGEvent>?

  init(event: CGEvent, eventSource: CGEventSource?,
       type: CGEventType, result: Unmanaged<CGEvent>?) {
    self.keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    self.event = event
    self.eventSource = eventSource
    self.type = type
    self.result = result
  }
}
