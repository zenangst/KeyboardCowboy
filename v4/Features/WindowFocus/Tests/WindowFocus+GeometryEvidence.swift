import CoreGraphics

// A diagnostic comparison, never a window identity or a target for actions.
enum GeometryEvidence: Equatable {
  case unmatched
  case ambiguous
  case candidate(CGWindowID)

  struct CGWindow {
    let id: CGWindowID
    let pid: pid_t
    let frame: CGRect
  }

  static func assess(axFrames: [CGRect], pid: pid_t, cgWindows: [CGWindow]) -> [Self] {
    let ownedWindows = cgWindows.filter { $0.pid == pid && $0.id != 0 }

    return axFrames.map { frame in
      guard !frame.isEmpty, [frame.minX, frame.minY, frame.maxX, frame.maxY].allSatisfy(\.isFinite) else {
        return .unmatched
      }

      let matches = ownedWindows.filter { $0.frame == frame }
      guard let first = matches.first else { return .unmatched }
      guard axFrames.filter({ $0 == frame }).count == 1, matches.count == 1 else { return .ambiguous }

      return .candidate(first.id)
    }
  }
}
