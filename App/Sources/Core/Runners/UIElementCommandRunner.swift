import ApplicationServices
import Cocoa
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
//    var counter = 0
//    let start = CACurrentMediaTime()
//    defer {
//      print("⏱️ UIElementCommandRunner.run(\(counter)): \(CACurrentMediaTime() - start)")
//    }

    let focusedElement = try systemElement.focusedUIElement()
    guard let focusedWindow = focusedElement.window else {
      throw UIElementCommandRunnerError.unableToFindWindow
    }

    let mouseBasedRoles: Set<String> = [kAXStaticTextRole, kAXCellRole]

    let handler: (UIElementCommand.Predicate, AccessibilityElement?, inout Bool) -> Bool = { predicate, element, abort in
//      counter += 1
      guard let element else { return false }

      if Task.isCancelled {
        abort = true
        return false
      }

      if predicate.kind != .any {
        guard element.role == predicate.kind.axValue else { return false }
      }

      if predicate.properties.contains(.description),
         predicate.compare.run(lhs: element.description, rhs: predicate.value)
      { return true }


      if predicate.properties.contains(.identifier),
         predicate.compare.run(lhs: element.identifier, rhs: predicate.value)
      { return true }

      if predicate.properties.contains(.title),
         predicate.compare.run(lhs: element.title, rhs: predicate.value)
      { return true }


      if predicate.properties.contains(.value),
         predicate.compare.run(lhs: element.value, rhs: predicate.value)
      { return true }

      return false
    }


    typealias PredicateType = [Int: (AccessibilityElement?, inout Bool) -> Bool]
    var predicates: PredicateType = command.predicates
      .enumerated()
      .reduce(into: [Int: (AccessibilityElement?, inout Bool) -> Bool]()) { (dict, pair) in
        let (index, predicate) = pair
        dict[index] = {
          handler(predicate, $0, &$1)
        }
      }

    var abort: Bool = false
    let elementMatches = focusedWindow.findChildren(matchingConditions: &predicates, abort: &abort)

    for (_, elementMatch) in elementMatches {
      try Task.checkCancellation()
      if let role = elementMatch.role,
         mouseBasedRoles.contains(role),
         let frame = elementMatch.frame,
         let mousePosition = CGEvent(source: nil)?.location {
        postMouseEvent(machPort?.eventSource, eventType: .leftMouse, location: frame.origin)
        try await Task.sleep(for: .milliseconds(50))
        postMouseEvent(machPort?.eventSource, eventType: .mouseMoved, location: mousePosition)
        return
      }

      elementMatch.performAction(.press)
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
