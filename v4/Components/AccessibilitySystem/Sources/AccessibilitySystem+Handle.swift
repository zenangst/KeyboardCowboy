import ApplicationServices
import Foundation

extension AccessibilitySystem {
  // Neither transport values nor native handles cross the serial-worker boundary.
  final class Handle: Hashable {
    let native: AXUIElement?
    private let fixtureIdentity: UUID

    init(native: AXUIElement? = nil) {
      self.native = native
      fixtureIdentity = UUID()
    }

    static func == (lhs: Handle, rhs: Handle) -> Bool {
      if let left = lhs.native, let right = rhs.native { return CFEqual(left, right) }
      return lhs.fixtureIdentity == rhs.fixtureIdentity
    }

    func hash(into hasher: inout Hasher) {
      if let native {
        hasher.combine(CFHash(native))
      } else {
        hasher.combine(fixtureIdentity)
      }
    }
  }
}
