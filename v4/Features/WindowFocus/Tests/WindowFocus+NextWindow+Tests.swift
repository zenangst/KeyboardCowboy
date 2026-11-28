import CoreGraphics
import Testing
@testable import WindowFocusFeature

@Test func rejectsSameProcessBeforeEnteringTheAXWorker() async throws {
  let raised = try await WindowFocus.nextWindow(in: getpid()) {
    Issue.record("The same-process target should be rejected before checking focus")
    return true
  }
  #expect(!raised)
}

@Test func cyclesByVerifiedIDEvenWhenRaisingChangesAXOrder() throws {
  let fixture = NextWindowFixture()
  #expect(try fixture.run())
  #expect(try fixture.run())
  #expect(try fixture.run())
  #expect(fixture.raised == [20, 30, 10])
}

@Test func previousPrefersHistoryOverTheReverseNeighbor() throws {
  let fixture = NextWindowFixture()
  fixture.focused = 30
  #expect(try fixture.run(.previous(.init(processIdentifier: 42, current: 30, previous: 10))))
  #expect(fixture.raised == [10])
}

private enum UnusableHistory: CaseIterable {
  case missing, staleCurrent, offScreen, differentApp, sameWindow
}

@Test(arguments: UnusableHistory.allCases)
private func previousCyclesBackwardWhenHistoryIsMissingOrIneligible(reason: UnusableHistory) throws {
  let fixture = NextWindowFixture()
  let history: WindowFocus.History? = switch reason {
  case .staleCurrent: .init(processIdentifier: 42, current: 30, previous: 20)
  case .offScreen: .init(processIdentifier: 42, current: 10, previous: 20)
  case .differentApp: .init(processIdentifier: 99, current: 10, previous: 20)
  case .sameWindow: .init(processIdentifier: 42, current: 10, previous: 10)
  case .missing: nil
  }
  if reason == .offScreen { fixture.owners?[20] = nil }
  #expect(try fixture.run(.previous(history)))
  #expect(fixture.raised == [30])
}

@Test func previousDoesNotRetargetIfHistoryWindowVanishedAfterSelection() throws {
  let fixture = NextWindowFixture()
  fixture.focused = 30
  fixture.afterFirstSnapshot = { fixture.owners?[10] = nil }
  #expect(try !fixture.run(.previous(.init(processIdentifier: 42, current: 30, previous: 10))))
  #expect(fixture.raised.isEmpty)
}

@Test func skipsOffScreenWrongOwnerAndAmbiguousIDs() throws {
  let fixture = NextWindowFixture()
  fixture.order = [10, 20, 30, 31, 40, 50, 51, 60]
  fixture.ids = [10: 10, 20: 20, 30: 30, 31: 30, 40: 40, 51: 0, 60: 60]
  fixture.owners = [10: [42], 30: [42], 40: [99], 51: [42], 60: [42]]
  #expect(try fixture.run())
  #expect(fixture.raised == [60])
}

@Test func noOpsWhenCurrentCannotBeVerifiedOrIsTheOnlyEligibleWindow() throws {
  let fixture = NextWindowFixture()
  fixture.bridgeAvailable = false
  #expect(try !fixture.run())
  fixture.bridgeAvailable = true
  fixture.owners = [20: [42]]
  #expect(try !fixture.run())
  fixture.owners = [10: [42]]
  #expect(try !fixture.run())
  #expect(fixture.raised.isEmpty)
}

private enum Invalidation: CaseIterable {
  case changedFocus, changedAssociation, windowLeftSpace, wrongOwner, changedApp, unavailableSnapshot
}

@Test(arguments: Invalidation.allCases)
private func rechecksAndDoesNotRetargetOnInvalidation(reason: Invalidation) throws {
  let fixture = NextWindowFixture()
  fixture.afterFirstSnapshot = {
    switch reason {
    case .changedFocus: fixture.focused = 30
    case .changedAssociation: fixture.ids[20] = 21
    case .windowLeftSpace: fixture.owners?.removeValue(forKey: 20)
    case .wrongOwner: fixture.owners?[20] = [99]
    case .changedApp: fixture.isActive = false
    case .unavailableSnapshot: fixture.owners = nil
    }
  }
  #expect(try !fixture.run())
  #expect(fixture.raised.isEmpty)
}

@Test func attemptsOneRaiseAndPropagatesFailure() {
  let fixture = NextWindowFixture()
  fixture.failRaise = true
  #expect(throws: NextWindowFixture.Failure.raise) { try fixture.run() }
  #expect(fixture.raised == [20])
  #expect(fixture.snapshots == 2)
}

@Test func tracesAcceptedRaiseSeparatelyFromASkippedRaise() throws {
  let fixture = NextWindowFixture()
  #expect(try fixture.run())
  #expect(fixture.trace == ["selected 20 from focused 10; eligible IDs [10, 20, 30]", "AX accepted raise of 20"])
  fixture.trace.removeAll()
  fixture.afterFirstSnapshot = { fixture.owners?[30] = nil }
  fixture.snapshots = 0
  #expect(try !fixture.run())
  #expect(fixture.trace.last == "skipped: focused or target ID no longer verified on-screen")
}

@Test func verifiesTheExactFocusedTargetAfterTheRaiseSettles() async throws {
  var samples: [CGWindowID?] = [10, nil, 20]
  var waits = 0
  let observed = try await Operation.Cycle.observeFocus(
    from: 10, to: 20, isCurrent: { true }, focusedID: { samples.removeFirst() }, wait: { waits += 1 },
  )
  #expect(observed && samples.isEmpty && waits == 2)
}

@Test func unobservedOrUnexpectedFocusDoesNotCountAsSuccess() async throws {
  var waits = 0
  #expect(try await !Operation.Cycle.observeFocus(
    from: 10, to: 20, isCurrent: { true }, focusedID: { 10 }, wait: { waits += 1 },
  ))
  #expect(waits == 4)
  #expect(try await !Operation.Cycle.observeFocus(
    from: 10, to: 20, isCurrent: { true }, focusedID: { 30 }, wait: { Issue.record("Unexpected retry") },
  ))

  var current = true
  #expect(try await !Operation.Cycle.observeFocus(
    from: 10, to: 20, isCurrent: { current }, focusedID: { current = false; return 20 },
    wait: { Issue.record("Unexpected retry") },
  ))
}

private final class NextWindowFixture {
  enum Failure: Error { case raise }

  var order = [30, 10, 20]
  var focused = 10
  var ids: [Int: CGWindowID] = [10: 10, 20: 20, 30: 30]
  var owners: [CGWindowID: Set<pid_t>]? = [10: [42], 20: [42], 30: [42]]
  var isActive = true
  var bridgeAvailable = true
  var failRaise = false
  var afterFirstSnapshot: (() -> Void)?
  var raised: [Int] = []
  var snapshots = 0
  var trace: [String] = []

  func run(_ direction: Operation.Cycle.Direction = .next) throws -> Bool {
    try Operation.Cycle.run(
      direction,
      in: 42, isAppActive: { isActive }, focusedWindow: { focused }, windows: { order },
      candidates: { windows in bridgeAvailable ? windows.map { ids[$0] } : nil },
      onScreenOwners: {
        snapshots += 1
        let snapshot = owners
        if snapshots == 1 {
          let update = afterFirstSnapshot
          afterFirstSnapshot = nil
          update?()
        }
        return snapshot
      },
      raise: { target in
        raised.append(target)
        if failRaise { throw Failure.raise }
        order.removeAll { $0 == target }
        order.insert(target, at: 0)
        focused = target
      },
      trace: { trace.append($0) },
    ) != nil
  }
}
