import AccessibilitySystem
import CoreGraphics

public extension HostInput {
  /// A value-only snapshot; no accessibility handle leaves the transaction.
  struct CapturedElement: Sendable {
    public let role: String?
    public let frame: CGRect
  }

  /// Takes a single snapshot at an AX global screen point. The caller owns
  /// input interception, capture lifetime, and coordinate conversion.
  static func captureElement(
    at point: CGPoint,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> CapturedElement {
    try await accessibility.withElement(at: point) { hit in
      let role: String?
      do {
        role = try hit.read(.role)
      } catch let failure as AccessibilitySystem.Failure
        where failure.kind == .noValue || failure.kind == .attributeUnsupported {
        role = nil
      }
      return CapturedElement(role: role, frame: try hit.frame())
    }
  }
}
