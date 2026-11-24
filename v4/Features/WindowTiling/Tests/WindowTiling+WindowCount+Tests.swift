import Testing
import WindowTilingFeature

private let fallbackCases: [(WindowTiling.Action, WindowTiling.Action, WindowTiling.Action)] = [
  (.arrangeLeftRight, .arrangeLeftRight, .arrangeLeftRight),
  (.arrangeRightLeft, .arrangeRightLeft, .arrangeRightLeft),
  (.arrangeTopBottom, .arrangeTopBottom, .arrangeTopBottom),
  (.arrangeBottomTop, .arrangeBottomTop, .arrangeBottomTop),
  (.arrangeLeftQuarters, .arrangeLeftRight, .arrangeLeftQuarters),
  (.arrangeRightQuarters, .arrangeRightLeft, .arrangeRightQuarters),
  (.arrangeTopQuarters, .arrangeTopBottom, .arrangeTopQuarters),
  (.arrangeBottomQuarters, .arrangeBottomTop, .arrangeBottomQuarters),
  (.arrangeQuarters, .arrangeLeftRight, .arrangeLeftQuarters),
]

@Test(arguments: fallbackCases)
func fixedArrangementFallbacks(
  action: WindowTiling.Action, two: WindowTiling.Action, three: WindowTiling.Action,
) {
  let expected: [WindowTiling.Action?] = [nil, .fill, two, three, action, action]
  for (count, result) in expected.enumerated() {
    #expect(WindowTiling.resolvedAction(action, eligibleWindowCount: count) == result)
  }
}

@Test func dynamicArrangementUsesTheSuppliedSide() {
  let expected: [(WindowTiling.Action?, WindowTiling.Action?)] = [
    (nil, nil), (.fill, .fill), (.arrangeLeftRight, .arrangeRightLeft),
    (.arrangeLeftQuarters, .arrangeRightQuarters), (.arrangeLeftQuarters, .arrangeRightQuarters),
    (.arrangeLeftQuarters, .arrangeRightQuarters),
  ]
  for (count, (left, right)) in expected.enumerated() {
    #expect(WindowTiling.resolvedAction(.arrangeDynamicQuarters, eligibleWindowCount: count, dynamicSide: .left) == left)
    #expect(WindowTiling.resolvedAction(.arrangeDynamicQuarters, eligibleWindowCount: count, dynamicSide: .right) == right)
    #expect(WindowTiling.resolvedAction(.arrangeDynamicQuarters, eligibleWindowCount: count) == (count == 1 ? .fill : nil))
  }
}

@Test func countResolutionLeavesSingleWindowActionsUnchangedAndSkipsUnavailableLayouts() async throws {
  #expect(WindowTiling.resolvedAction(.left, eligibleWindowCount: 1) == .left)
  #expect(WindowTiling.resolvedAction(.previousSize, eligibleWindowCount: 5) == .previousSize)
  #expect(WindowTiling.resolvedAction(.left, eligibleWindowCount: -1) == nil)
  let accepted = try await WindowTiling.execute(.arrangeQuarters, in: 123, eligibleWindowCount: 0)
  #expect(!accepted)
}
