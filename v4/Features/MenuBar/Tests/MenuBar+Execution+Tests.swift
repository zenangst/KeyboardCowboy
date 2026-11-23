import Foundation
@testable import MenuBarFeature
import Testing

@Test func picksFirstEnabledPrefixAheadOfExactAndSupportsAlternateNestedTitle() throws {
  let fixture = Fixture(
    children: [0: [1, 2, 3, 4], 3: [5], 5: [6]],
    titles: [1: "File", 3: "File Actions", 4: "File", 6: "Save a Copy…"],
    disabled: [1, 5],
  )
  #expect(try fixture.execute([.menuItem(name: "File"), .menuItems(name: "Duplicate", fallbackName: "Save a Copy")]))
  #expect(fixture.picks == [6])
  #expect(fixture.titleReads == [2, 3, 6])
  #expect(fixture.childReads == [0, 3, 5])
}

@Test func searchesLaterSiblingSubtreeAfterMissAndSkipsCycles() throws {
  let fixture = Fixture(
    children: [0: [1, 2], 1: [0, 1], 2: [3], 3: [2, 4]],
    titles: [4: "Zoom"],
  )
  #expect(try fixture.execute([.menuItem(name: "Zoom")]))
  #expect(fixture.childReads == [0, 1, 2, 3])
  #expect(fixture.picks == [4])
}

@Test func directMatchBeatsDescendantAndDoesNotTryLaterMatchesAfterNestedMiss() throws {
  let fixture = Fixture(children: [0: [1, 2, 3], 1: [4], 3: [5], 4: [6]],
                        titles: [2: "File Actions", 3: "File", 4: "File", 5: "Open", 6: "Open"])
  #expect(try !fixture.execute([.menuItem(name: "File"), .menuItem(name: "Open")]))
  #expect(fixture.childReads == [0, 2])
  #expect(fixture.picks.isEmpty)
}

@Test func emptyTokensAndAbsentMenuBarAreDifferentFromNoMatch() throws {
  let fixture = Fixture(hasRoot: false)
  #expect(throws: MenuBar.ExecutionError.emptyTokens) {
    try fixture.execute([])
  }
  #expect(fixture.rootReads == 0)
  #expect(throws: MenuBar.ExecutionError.menuBarUnavailable) {
    try fixture.execute([.menuItem(name: "File")])
  }
  #expect(fixture.rootReads == 1)
  #expect(fixture.picks.isEmpty)
}

@Test func readAndPickFailuresPropagateWithoutRetry() throws {
  let fixture = Fixture(children: [0: [1, 2]], titles: [2: "File"])
  fixture.unreadable = 1
  #expect(throws: Fixture.Failure.read) {
    try fixture.execute([.menuItem(name: "File")])
  }
  #expect(fixture.picks.isEmpty)
  fixture.unreadable = nil
  fixture.failPick = true
  #expect(throws: Fixture.Failure.pick) {
    try fixture.execute([.menuItem(name: "File")])
  }
  #expect(fixture.picks == [2])
}

@Test func boundsTraversalAcrossTokensAndChecksCancellationBeforePick() throws {
  let fixture = Fixture(children: [0: [1], 1: [2]], titles: [1: "File", 2: "Open"])
  let tokens: [MenuBar.Token] = [.menuItem(name: "File"), .menuItem(name: "Open")]
  #expect(throws: MenuBar.ExecutionError.traversalLimitReached) {
    try fixture.execute(tokens, nodes: 2)
  }
  #expect(throws: MenuBar.ExecutionError.traversalLimitReached) {
    try fixture.execute(tokens, depth: 1)
  }
  fixture.cancelAfterTitle = 2
  #expect(throws: CancellationError.self) {
    try fixture.execute(tokens)
  }
  #expect(fixture.picks.isEmpty)
}

@Test func decodesLegacyTokenLabels() throws {
  let data = Data(#"[{"menuItem":{"name":"Window"}},{"menuItems":{"name":"Fill","fallbackName":"Zoom"}}]"#.utf8)
  #expect(try JSONDecoder().decode([MenuBar.Token].self, from: data) == [
    .menuItem(name: "Window"), .menuItems(name: "Fill", fallbackName: "Zoom"),
  ])
}

private final class Fixture {
  enum Failure: Error { case read, pick }

  var rootReads = 0
  var childReads: [Int] = []
  var titleReads: [Int] = []
  var picks: [Int] = []
  var unreadable: Int?
  var failPick = false
  var cancelAfterTitle: Int?
  private var cancelled = false
  private let hasRoot: Bool
  private let children: [Int: [Int]]
  private let titles: [Int: String]
  private let disabled: Set<Int>

  init(hasRoot: Bool = true, children: [Int: [Int]] = [:], titles: [Int: String] = [:], disabled: Set<Int> = []) {
    self.hasRoot = hasRoot
    self.children = children
    self.titles = titles
    self.disabled = disabled
  }

  func execute(_ tokens: [MenuBar.Token], nodes: Int = 1000, depth: Int = 64) throws -> Bool {
    try MenuBar.execute(tokens, budget: .init(maximumNodes: nodes, maximumDepth: depth), root: {
      rootReads += 1
      return hasRoot ? 0 : nil
    }, children: {
      childReads.append($0)
      return children[$0, default: []]
    }, enabled: {
      !disabled.contains($0)
    }, title: {
      titleReads.append($0)
      if $0 == unreadable { throw Failure.read }
      if $0 == cancelAfterTitle { cancelled = true }
      return titles[$0]
    }, checkpoint: {
      if cancelled { throw CancellationError() }
    }, pick: {
      picks.append($0)
      if failPick { throw Failure.pick }
    })
  }
}
