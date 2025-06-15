import AXEssibility
import AppKit
import CoreGraphics
import Foundation

enum MouseCommandRunnerError: Error {
  case unableToResolveFrame
}

class MouseCommandRunner {
  func run(_ command: MouseCommand, snapshot: UserSpace.Snapshot) async throws {
    let source = CGEventSource(stateID: .hidSystemState)

    switch command.kind.element {
    case .focused:
      let systemElement = SystemAccessibilityElement()
      let focusedElement = try systemElement.focusedUIElement()
      let rawRoleDescription = try focusedElement.value(.roleDescription, as: String.self)

      guard let roleDescription = KnownAccessibilityRoleDescription(rawValue: rawRoleDescription) else {
        #if DEBUG
        print("Ignored:", rawRoleDescription)
        #endif
        return
      }

      let frame: CGRect
      if let customRoutine = CustomMouseRoutine(rawValue: snapshot.frontMostApplication.bundleIdentifier)?
        .routine(roleDescription: roleDescription) {
        frame = try customRoutine.run(focusedElement, kind: command.kind, roleDescription: roleDescription)
      } else {
        frame = switch roleDescription {
        case .collection: try AXCollectionResolver.resolveFocusedElement(focusedElement)
        case .editor: try AXEditorResolver.resolveFocusedElement(focusedElement)
        case .group: try AXGroupResolver.resolveFocusedElement(AnyAccessibilityElement(focusedElement.reference))
        case .htmlContent: try AXHTMLResolver.resolveFocusedElement(focusedElement, snapshot: snapshot)
        case .list: try AXListResolver.resolveFocusedElement(focusedElement)
        case .outline: try AXOutlineResolver.resolveFocusedElement(focusedElement)
        case .scrollArea: try AXScrollAreaResolver.resolveFocusedElement(focusedElement)
        case .table: try AXTableResolver.resolveFocusedElement(focusedElement)
        case .textEntryArea: try AXTextEntryAreaResolver.resolveFocusedElement(focusedElement)
        default: try AnyAccessibilityElement(focusedElement.reference).getFrame()
        }
      }

      var targetLocation: CGPoint

      if case .focused(let clickLocation) = command.kind.element {
        targetLocation = switch clickLocation {
        case .topLeading: CGPoint(x: frame.origin.x, y: frame.origin.y)
        case .top: CGPoint(x: frame.midX, y: frame.origin.y)
        case .topTrailing: CGPoint(x: frame.maxX, y: frame.origin.y)
        case .leading: CGPoint(x: frame.origin.x, y: frame.midY)
        case .center: CGPoint(x: frame.midX, y: frame.midY)
        case .trailing: CGPoint(x: frame.maxX, y: frame.midY)
        case .bottomLeading: CGPoint(x: frame.origin.x, y: frame.maxY)
        case .bottom: CGPoint(x: frame.midX, y: frame.maxY)
        case .bottomTrailing: CGPoint(x: frame.maxX, y: frame.maxY)
        case .custom(let x, let y): CGPoint(x: x, y: y)
        }
      } else {
        targetLocation = CGPoint(x: frame.midX, y: frame.midY)
      }

      targetLocation = targetLocation.applying(.init(translationX: 5, y: 5))

      guard let currentLocation = CGEvent(source: nil)?.location else { return }

      switch command.kind {
      case .doubleClick:
        postMouseEvent(source, eventType: .leftMouse, clickCount: 2, location: targetLocation)
      case .click:
        postMouseEvent(source, eventType: .leftMouse, location: targetLocation)
      case .rightClick:
        postMouseEvent(source, eventType: .rightMouse, location: targetLocation)
      }

      try await Task.sleep(for: .milliseconds(50))
      postMouseEvent(source, eventType: .mouseMoved, location: currentLocation)
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

enum MouseEventType {
  case leftMouse
  case rightMouse
  case mouseMoved

  var downType: CGEventType {
    switch self {
    case .leftMouse: .leftMouseDown
    case .rightMouse: .rightMouseDown
    case .mouseMoved: .mouseMoved
    }
  }

  var upType: CGEventType {
    switch self {
    case .leftMouse: .leftMouseUp
    case .rightMouse: .rightMouseUp
    case .mouseMoved: .mouseMoved
    }
  }

  var mouseButton: CGMouseButton {
    switch self {
    case .leftMouse: .left
    case .rightMouse: .right
    case .mouseMoved: .left
    }
  }
}

enum KnownAccessibilityRoleDescription: String {
  case collection
  case editor
  case group
  case htmlContent = "HTML content"
  case image
  case list
  case outline
  case outlineRow = "outline row"
  case scrollArea = "scroll area"
  case table
  case text
  case textEntryArea = "text entry area"
  case textField = "text field"
}

extension AnyAccessibilityElement {
  func getFrame() throws -> CGRect {
    if let frame = frame {
      return frame
    } else {
      throw MouseCommandRunnerError.unableToResolveFrame
    }
  }
}
