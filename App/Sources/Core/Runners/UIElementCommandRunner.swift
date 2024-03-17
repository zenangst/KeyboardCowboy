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

  private var restore: [Int32: Bool] = [:]

  func run(_ command: UIElementCommand, checkCancellation: Bool) async throws {
    guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return }
    //    var counter = 0
    //    let start = CACurrentMediaTime()
    //    defer {
    //      print("⏱️ UIElementCommandRunner.run(\(counter)): \(CACurrentMediaTime() - start)")
    //    }

    let app = AppAccessibilityElement(pid)
    if let appEnhancedUserInterface = app.enhancedUserInterface {
      app.enhancedUserInterface = true
      if restore[pid] == nil { restore[pid] = appEnhancedUserInterface }
    }
    _ = AXUIElementSetAttributeValue(app.reference, "AXManualAccessibility" as CFString, true as CFTypeRef)
    try await Task.sleep(for: .milliseconds(75))

    let focusedWindow: WindowAccessibilityElement?
    do {
      focusedWindow = try systemElement.focusedUIElement().window
    } catch {
      focusedWindow = try app.focusedWindow()
    }

    guard let focusedWindow = focusedWindow,
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
      checkCancellation ? Task.isCancelled : false
    }) { values in
//      counter += 1
      for predicate in predicates {
        guard let role = values[.role] as? String else { continue }

        mouseBasedRole = mouseBasedRoles.contains(role)

        if predicate.kind != .any {
          guard values[.role] as? String == predicate.kind.axValue else { return false }
        }

        if predicate.properties.contains(.description),
           let value = values[.description] as? String,
           predicate.compare.run(lhs: value, rhs: predicate.value){
          return true
        }

        if predicate.properties.contains(.identifier),
           let value = values[.identifier] as? String,
           predicate.compare.run(lhs: value, rhs: predicate.value) {
          return true
        }

        if predicate.properties.contains(.title),
           let value = values[.title] as? String,
           predicate.compare.run(lhs: value, rhs: predicate.value) {
          return true
        }

        if predicate.properties.contains(.value),
           let value = values[.value] as? String,
           predicate.compare.run(lhs: value, rhs: predicate.value) {
          return true
        }
      }
      
      return false
    }

    defer {
      restoreEnhancedUserInterface()
    }

    guard let subject else {

      return
    }

    if checkCancellation { try Task.checkCancellation() }

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

  private func restoreEnhancedUserInterface() {
    for (pid, value) in restore { AppAccessibilityElement(pid).enhancedUserInterface = value }
    restore.removeAll()
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
