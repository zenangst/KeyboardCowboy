import ApplicationServices
import MachPort
import AXEssibility
import Foundation

enum UIElementCommandRunnerError: Error {
  case unableToFindWindow
}

final class UIElementCommandRunner {
  var machPort: MachPortEventController?
  let systemElement: SystemAccessibilityElement = .init()

  func run(_ command: UIElementCommand) async throws {
    let focusedElement = try systemElement.focusedUIElement()
    guard let focusedWindow = focusedElement.window else {
      throw UIElementCommandRunnerError.unableToFindWindow
    }

    var moreThanOne = command.predicates.count > 1
    for predicate in command.predicates {
      var result = focusedWindow.findChild { element in
        guard let element else { return false }

        if predicate.kind != .any {
          guard element.role == predicate.kind.axValue else { return false }
        }

        if predicate.properties.contains(.description),
           predicate.compare.run(lhs: predicate.value, rhs: element.description)
        { return true }


        if predicate.properties.contains(.identifier),
           predicate.compare.run(lhs: predicate.value, rhs: element.identifier)
        { return true }


        if predicate.properties.contains(.title),
           predicate.compare.run(lhs: predicate.value, rhs: element.title)
        { return true }


        if predicate.properties.contains(.value),
           predicate.compare.run(lhs: predicate.value, rhs: element.value)
        { return true }

        return false
      }

      if result?.role == kAXStaticTextRole,
         let frame = result?.frame,
         let mousePosition = CGEvent(source: nil)?.location {
        postMouseEvent(machPort?.eventSource, eventType: .leftMouse, location: frame.origin)
        try await Task.sleep(for: .milliseconds(50))
        postMouseEvent(machPort?.eventSource, eventType: .mouseMoved, location: mousePosition)
        return
      }

      result?.performAction(.press)
      if moreThanOne {
        try await Task.sleep(for: .milliseconds(100))
      }
    }
  }

  private func postMouseEvent(
    _ source: CGEventSource?,
    eventType: MouseEventType,
    clickCount: Int64 = 1,
    location: CGPoint
  ) {
    let eventDown = CGEvent(
      mouseEventSource: source,
      mouseType: eventType.downType,
      mouseCursorPosition: location,
      mouseButton: eventType.mouseButton
    )
    eventDown?.flags = CGEventFlags(rawValue: 0)
    let eventUp = CGEvent(
      mouseEventSource: source,
      mouseType: eventType.upType,
      mouseCursorPosition: location,
      mouseButton: eventType.mouseButton
    )
    eventUp?.flags = CGEventFlags(rawValue: 0)

    if clickCount > 1 {
      eventDown?.setIntegerValueField(.mouseEventClickState, value: clickCount)
      eventUp?.setIntegerValueField(.mouseEventClickState, value: clickCount)
    }

    eventDown?.post(tap: .cghidEventTap)
    eventUp?.post(tap: .cghidEventTap)
  }
}
