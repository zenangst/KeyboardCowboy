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
    guard let focusedWindow = focusedElement.window,
          let screen = NSScreen.main else {
      throw UIElementCommandRunnerError.unableToFindWindow
    }

    let handler: (UIElementCommand.Predicate, AnyAccessibilitySubject?, inout Bool) -> Bool = { predicate, subject, abort in
      guard let subject else { return false }

      let element = subject.element

      if Task.isCancelled {
        abort = true
        return false
      }

//      counter += 1

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

    typealias PredicateType = [Int: (AnyAccessibilitySubject, inout Bool) -> Bool]
    var predicates: PredicateType = command.predicates
      .enumerated()
      .reduce(into: PredicateType()) { (dict, pair) in
        let (index, predicate) = pair
        dict[index] = {
          handler(predicate, $0, &$1)
        }
      }

    var abort: Bool = false
    let elementSubjects = focusedWindow.findChildren(
      screen: screen,
      matchingConditions: &predicates,
      abort: &abort
    )

    let mouseBasedRoles: Set<String> = [kAXStaticTextRole, kAXCellRole]
    for (_, subject) in elementSubjects {
      try Task.checkCancellation()
      if let mousePosition = CGEvent(source: nil)?.location,
         let role = subject.element.role,
         mouseBasedRoles.contains(role) {
        CGEvent.performClick(
          machPort?.eventSource,
          eventType: .leftMouse,
          at: subject.position
        )
        try await Task.sleep(for: .milliseconds(50))
        CGEvent.restoreMousePosition(to: mousePosition)
        return
      }
      subject.element.performAction(.press)
    }
  }
}

fileprivate extension CGEvent {
  static func restoreMousePosition(to origin: CGPoint) {
    let eventDown = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                            mouseCursorPosition: origin, mouseButton: .left)
    eventDown?.flags = CGEventFlags(rawValue: 0)
    eventDown?.post(tap: .cghidEventTap)
  }

  static func performClick(_ source: CGEventSource?,
                           eventType: MouseEventType,
                           clickCount: Int64 = 1,
                           at location: CGPoint) {
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
