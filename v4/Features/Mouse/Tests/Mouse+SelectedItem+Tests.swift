@testable import MouseFeature
import Testing

@Test(arguments: [false, true])
func laterGroupReplacesEarlierMatchButFirstSelectedItemWinsWithinGroup(collection: Bool) throws {
  var reads: [Int] = []
  let tree = collection ? [0: [1, 2, 3], 1: [10, 11], 2: [20, 21], 3: [30]]
    : [1: [10, 11], 2: [20, 21], 3: [30]]
  let result = try Mouse.selectedItem(
    in: collection ? [0] : [1, 2, 3], collection: collection,
    children: { tree[$0] ?? [] }, focused: { _ in false }, selected: {
      reads.append($0)
      return $0 != 30
    }, checkpoint: {})
  #expect(result == 20)
  #expect(reads == [10, 20, 30])
}

@Test func focusedListLeafStopsTheSearchAfterAnEarlierSelection() throws {
  enum Failure: Error { case missingChildren }
  let result = try Mouse.selectedItem(
    in: [1, 2, 3], collection: false, children: {
      if $0 == 3 { Issue.record("Unexpected read after focused leaf") }
      if $0 == 2 { throw Failure.missingChildren }
      return [10]
    }, focused: { $0 == 2 }, selected: { $0 == 10 }, checkpoint: {})
  #expect(result == 2)
}

@Test func collectionDoesNotTreatFocusedLeavesAsSelected() throws {
  let result = try Mouse.selectedItem(
    in: [1], collection: true, children: { _ in [] }, focused: { _ in
      Issue.record("Unexpected focus read")
      return true
    }, selected: { _ in false }, checkpoint: {})
  #expect(result == nil)
}

@Test func nestedCancellationDoesNotTriggerFocusedLeafFallback() {
  #expect(throws: CancellationError.self) {
    try Mouse.selectedItem(
      in: [1], collection: false, children: { _ in throw CancellationError() },
      focused: { _ in Issue.record("Unexpected focus read"); return true },
      selected: { _ in false }, checkpoint: {})
  }
}
