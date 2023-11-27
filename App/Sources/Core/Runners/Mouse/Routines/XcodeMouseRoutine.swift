import AXEssibility
import Foundation

enum XcodeMouseRoutineError: Error {
  case unableToResolveFrame
}

final class XcodeMouseRoutine: MouseRoutine {
  let supportedRoleDescriptions: [KnownAccessibilityRoleDescription] = [
    .textEntryArea
  ]

  init?(_ roleDescription: KnownAccessibilityRoleDescription) {
    guard supportedRoleDescriptions.contains(roleDescription) else { return nil }
  }

  func run(_ focusedElement: AnyFocusedAccessibilityElement, 
           kind: MouseCommand.Kind,
           roleDescription: KnownAccessibilityRoleDescription) throws -> CGRect {
    let elementFrame = try AXTextEntryAreaResolver.resolveFocusedElement(focusedElement)
    let frame: CGRect
    if case .focused(let clickLocation) = kind.element,
       case .center = clickLocation {
      frame = elementFrame
    } else if let resolvedFrame = focusedElement.frame {
      frame = CGRect(
        origin: CGPoint(
          x: resolvedFrame.origin.x + 8,
          y: elementFrame.origin.y
        ),
        size: elementFrame.size
      )
    } else {
      throw XcodeMouseRoutineError.unableToResolveFrame
    }

    return frame
  }
}
