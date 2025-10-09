import AXEssibility
import Foundation

enum XcodeMouseRoutineError: Error {
  case unableToResolveFrame
}

final class XcodeMouseRoutine: MouseRoutine {
  let supportedRoleDescriptions: [KnownAccessibilityRoleDescription] = [
    .textEntryArea,
  ]

  init?(_ roleDescription: KnownAccessibilityRoleDescription) {
    guard supportedRoleDescriptions.contains(roleDescription) else { return nil }
  }

  func run(_ focusedElement: AnyFocusedAccessibilityElement,
           kind: MouseCommand.Kind,
           roleDescription _: KnownAccessibilityRoleDescription) throws -> CGRect
  {
    let elementFrame = try AXTextEntryAreaResolver.resolveFocusedElement(focusedElement)
    let frame: CGRect
    if case .center = kind.element.clickLocation {
      frame = elementFrame
    } else if let resolvedFrame = focusedElement.frame {
      frame = switch kind.element.clickLocation {
      case .leading:
        CGRect(
          origin: CGPoint(
            x: resolvedFrame.origin.x + 8,
            y: elementFrame.origin.y,
          ),
          size: elementFrame.size,
        )
      case .trailing:
        CGRect(
          origin: CGPoint(
            x: resolvedFrame.maxX - 16,
            y: elementFrame.origin.y,
          ),
          size: elementFrame.size,
        )
      default:
        CGRect(
          origin: CGPoint(
            x: resolvedFrame.origin.x + 8,
            y: elementFrame.origin.y,
          ),
          size: elementFrame.size,
        )
      }
    } else {
      throw XcodeMouseRoutineError.unableToResolveFrame
    }

    return frame
  }
}
