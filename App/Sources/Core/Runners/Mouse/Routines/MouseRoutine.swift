import AXEssibility
import Foundation

protocol MouseRoutine {
  init?(_ roleDescription: KnownAccessibilityRoleDescription) 
  func run(_ focusedElement: AnyFocusedAccessibilityElement,
           kind: MouseCommand.Kind,
           roleDescription: KnownAccessibilityRoleDescription) throws -> CGRect
}
