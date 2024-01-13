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

    let predicates = command.predicates
    var keys = predicates
      .flatMap { $0.properties.map(\.axValue) }
      .compactMap(NSAccessibility.Attribute.init(rawValue:))
    keys.append(.role)

    let mouseBasedRoles: Set<String> = [kAXStaticTextRole, kAXCellRole]
    var mouseBasedRole: Bool = false

    let subject = focusedWindow.findChild(on: screen, keys: Set(keys), abort: {
      let result = Task.isCancelled
      return result
    }) { values in
//      counter += 1
      for predicate in predicates {
        guard let role = values[.role] as? String else { continue }

        mouseBasedRole = mouseBasedRoles.contains(role)

        if predicate.kind != .any {
          guard values[.role] as? String == predicate.kind.axValue else { return false }
        }

        if predicate.properties.contains(.description),
           values[ .description] as? String == predicate.value {
          return true
        }

        if predicate.properties.contains(.identifier),
           values[.identifier] as? String == predicate.value {
          return true
        }

        if predicate.properties.contains(.title),
           values[.title] as? String == predicate.value {
          return true
        }

        if predicate.properties.contains(.value),
           values[.value] as? String == predicate.value {
          return true
        }
      }
      
      return false
    }

    guard let subject else { return }

    try Task.checkCancellation()
    if let mousePosition = CGEvent(source: nil)?.location,
       mouseBasedRole {
      CGEvent.performClick(
        machPort?.eventSource,
        eventType: .leftMouse,
        at: subject.position
      )
      try await Task.sleep(for: .milliseconds(10))
      CGEvent.restoreMousePosition(to: mousePosition)
      return
    }
    subject.element.performAction(.press)
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
