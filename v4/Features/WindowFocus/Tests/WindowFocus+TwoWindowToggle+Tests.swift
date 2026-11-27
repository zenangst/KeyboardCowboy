import CoreGraphics
import Testing
import WindowFocusFeature

private typealias Search = WindowFocus.DirectionalSearch
private let left = Search.Window(id: 1, frame: CGRect(x: -450, y: 100, width: 300, height: 250))
private let right = Search.Window(id: 2, frame: CGRect(x: 200, y: 100, width: 300, height: 250))
private let displays = [
  CGRect(x: -500, y: 0, width: 500, height: 600),
  CGRect(x: 100, y: 0, width: 500, height: 600),
]

@Test(arguments: Search.Direction.allCases)
func twoWindowToggleUsesExactIdentityInEitherDirectionAcrossDisplays(
  direction: WindowFocus.DirectionalSearch.Direction,
) throws {
  for (anchor, target) in [(left, right), (right, left)] {
    var resolved: [CGWindowID] = []
    let match = try Search.select(
      from: anchor, windows: [left, right], direction: direction, visibleFrames: displays,
      resolveAXIdentity: { candidate in
        resolved.append(candidate.id)
        return candidate.id
      },
    ) { _ in
      Issue.record("The verified toggle should not probe")
      return nil
    }
    #expect(resolved == [target.id])
    #expect(match?.windowID == target.id)
    #expect(match?.direction == direction)
    #expect(match?.branch == .twoWindowToggle)
  }
}

@Test(arguments: [nil, 1, 999] as [CGWindowID?])
func unavailableOrMismatchedToggleIdentityFallsBackToTheDirectionalProbe(resolvedID: CGWindowID?) throws {
  let target = Search.Window(id: 2, frame: CGRect(x: -950, y: 100, width: 400, height: 250))
  let display = CGRect(x: -1100, y: 0, width: 1100, height: 600)
  var probes: [CGPoint] = []
  let match = try Search.select(
    from: left, windows: [left, target], direction: .left, visibleFrames: [display],
    resolveAXIdentity: { _ in resolvedID },
  ) { point in
    probes.append(point)
    return target.frame.contains(point) ? target.id : nil
  }
  #expect(probes == [.init(x: -525, y: 125), .init(x: -575, y: 125)])
  #expect(match?.windowID == target.id)
  #expect(match?.branch == .directHit)

  let miss = try Search.select(
    from: left, windows: [left, target], direction: .left, visibleFrames: [display],
    resolveAXIdentity: { _ in resolvedID },
  ) { _ in nil }
  #expect(miss == nil)
}

@Test func resolverIsNotUsedWithoutASingleAlternative() throws {
  let third = Search.Window(id: 3, frame: CGRect(x: -500, y: 0, width: 500, height: 600))
  for inventory in [[left], [left, right, third]] {
    let match = try Search.select(
      from: left, windows: inventory, direction: .down, visibleFrames: displays,
      resolveAXIdentity: { _ in
        Issue.record("Only the two-window path should resolve by ID")
        return right.id
      },
    ) { _ in third.id }
    #expect(match?.windowID == (inventory.count == 1 ? nil : third.id))
    #expect(match?.branch == (inventory.count == 1 ? nil : .directHit))
  }
}

@Test func cancellationDuringToggleResolutionDoesNotSelectOrProbe() async {
  let task = Task {
    try Search.select(from: left, windows: [left, right], direction: .right, visibleFrames: displays,
                      resolveAXIdentity: { candidate in
                        withUnsafeCurrentTask { $0?.cancel() }
                        return candidate.id
                      }) { _ in
      Issue.record("Cancelled selection must not probe")
      return nil
    }
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}
