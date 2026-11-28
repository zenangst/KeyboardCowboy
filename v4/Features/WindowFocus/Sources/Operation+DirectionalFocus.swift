import AccessibilitySystem
import CoreGraphics

extension Operation {
  struct DirectionalFocus: Sendable {
    typealias Search = WindowFocus.DirectionalSearch

    let direction: Search.Direction
    let visibleFrames: [CGRect]
    let tiling: Search.Tiling?
    let spacing: CGFloat
    let mainDisplayFrame: CGRect?
    let deadzoneSpacing: CGFloat?

    func callAsFunction(
      anchorID: CGWindowID, candidates: [(id: CGWindowID, owner: pid_t, frame: CGRect)],
      session: AccessibilitySystem.Session, isCurrent: @escaping () -> Bool,
    ) throws -> CGWindowID? {
      func checkpoint() throws -> Bool {
        try session.checkpoint()
        return isCurrent()
      }

      let owners = Dictionary(grouping: candidates, by: \.id)
      guard try checkpoint(), let anchors = owners[anchorID], anchors.count == 1, let anchor = anchors.first else {
        return nil
      }
      let windows = candidates.filter { owners[$0.id]?.count == 1 }.map { Search.Window(id: $0.id, frame: $0.frame) }
      let match = try Search.select(
        from: .init(id: anchorID, frame: anchor.frame), windows: windows, direction: direction,
        visibleFrames: visibleFrames, tiling: tiling, spacing: spacing, mainDisplayFrame: mainDisplayFrame,
        deadzoneSpacing: deadzoneSpacing,
        resolveAXIdentity: { candidate in
          guard try checkpoint(), let owner = owners[candidate.id]?.first?.owner else { return nil }
          return try Self.unavailableAsMiss {
            var found = false
            for window in try session.windows(in: owner) where try session.windowIDCandidate(for: window) == candidate.id {
              guard !found else { return nil }
              found = true
            }
            return found ? candidate.id : nil
          }
        },
      ) { point in
        guard try checkpoint() else { return nil }
        return try Self.unavailableAsMiss {
          guard let window = try session.window(at: point) else { return nil }
          return try session.windowIDCandidate(for: window)
        }
      }
      return try checkpoint() ? match?.windowID : nil
    }

    private static func unavailableAsMiss(
      _ read: () throws -> CGWindowID?,
    ) throws -> CGWindowID? {
      do {
        return try read()
      } catch let failure as AccessibilitySystem.Failure
        where failure.kind == .noValue || failure.kind == .attributeUnsupported || failure.kind == .invalidElement {
        return nil
      }
    }
  }
}
