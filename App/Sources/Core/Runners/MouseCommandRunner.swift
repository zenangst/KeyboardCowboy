import AXEssibility
import AppKit
import CoreGraphics
import Foundation
import MachPort

class MouseCommandRunner {
  func run(_ command: MouseCommand, snapshot: UserSpace.Snapshot) async throws {
    let source = CGEventSource(stateID: .hidSystemState)

    switch command.kind.element {
    case .focused:
      let systemElement = SystemAccessibilityElement()
      let focusedElement = try systemElement.focusedUIElement()
      let roleDescription = try focusedElement.value(.roleDescription, as: String.self)


      guard let type = KnownAccessibilityElement(rawValue: roleDescription) else {
        print("Ignored:", roleDescription)
        return
      }

      let match: AnyAccessibilityElement

      switch type {
      case .outline:
        match = try AXOutlineResolver.resolveFocusedElement(focusedElement)
      case .collection:
        match = try AXCollectionResolver.resolveFocusedElement(focusedElement)
      case .group:
        match = try AXGroupResolver.resolveFocusedElement(AnyAccessibilityElement(focusedElement.reference))
      case .list:
        match = try AXListResolver.resolveFocusedElement(focusedElement)
      case .scrollArea:
        match = try AXScrollAreaResolver.resolveFocusedElement(focusedElement)
      default:
        match = AnyAccessibilityElement(focusedElement.reference)
      }

      guard let frame = match.frame else { return }

      var targetLocation: CGPoint

      if case .focused(let clickLocation) = command.kind.element {
        switch clickLocation {
        case .topLeading:
          targetLocation = CGPoint(x: frame.origin.x, y: frame.origin.y)
        case .top:
          targetLocation = CGPoint(x: frame.midX, y: frame.origin.y)
        case .topTrailing:
          targetLocation = CGPoint(x: frame.maxX, y: frame.origin.y)
        case .leading:
          targetLocation = CGPoint(x: frame.origin.x, y: frame.midY)
        case .center:
          targetLocation = CGPoint(x: frame.midX, y: frame.midY)
        case .trailing:
          targetLocation = CGPoint(x: frame.maxX, y: frame.midY)
        case .bottomLeading:
          targetLocation = CGPoint(x: frame.origin.x, y: frame.maxY)
        case .bottom:
          targetLocation = CGPoint(x: frame.midX, y: frame.maxY)
        case .bottomTrailing:
          targetLocation = CGPoint(x: frame.maxX, y: frame.maxY)
        case .custom(let x, let y):
          targetLocation = CGPoint(x: x, y: y)
        }
      } else {
        targetLocation = CGPoint(x: frame.midX, y: frame.midY)
      }

      targetLocation = targetLocation.applying(.init(translationX: 5, y: 5))

      switch command.kind {
      case .doubleClick:
        postMouseEvent(source, eventType: .leftMouse, clickCount: 2, location: targetLocation)
      case .click:
        postMouseEvent(source, eventType: .leftMouse, location: targetLocation)
      case .rightClick:
        postMouseEvent(source, eventType: .rightMouse, location: targetLocation)
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

fileprivate enum MouseEventType {
  case leftMouse
  case rightMouse

  var downType: CGEventType {
    switch self {
    case .leftMouse: .leftMouseDown
    case .rightMouse: .rightMouseDown
    }
  }

  var upType: CGEventType {
    switch self {
    case .leftMouse: .leftMouseUp
    case .rightMouse: .rightMouseUp
    }
  }

  var mouseButton: CGMouseButton {
    switch self {
    case .leftMouse: .left
    case .rightMouse: .right
    }
  }
}

enum KnownAccessibilityElement: String {
  case collection
  case list
  case outline
  case textEntryArea = "text entry area"
  case textField = "text field"
  case text
  case image
  case group
  case scrollArea = "scroll area"
}
