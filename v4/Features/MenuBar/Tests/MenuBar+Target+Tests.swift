import Commands
import Foundation
@testable import MenuBarFeature
import Testing

@MainActor
@Test func menuBarUsesFrontmostAppWithoutActivatingAndReturnsPickResult() async throws {
  let fixture = TargetFixture()
  fixture.frontmost = 17
  fixture.pickResult = false
  #expect(try await !fixture.execute(explicit: false))
  #expect(fixture.events == [.frontmost, .pick(17, TargetFixture.tokens)])
}

@MainActor
@Test func menuBarMissingFrontmostDoesNotPick() async throws {
  let fixture = TargetFixture()
  await #expect(throws: MenuBar.TargetError.frontmostApplicationUnavailable) {
    try await fixture.execute(explicit: false)
  }
  #expect(fixture.events == [.frontmost])
}

@MainActor
@Test(arguments: [true, false])
func menuBarUsesFirstRunningInstanceAndOnlyActivatesWhenNeeded(alreadyFrontmost: Bool) async throws {
  let fixture = TargetFixture()
  fixture.running = [17, 18]
  fixture.frontmost = alreadyFrontmost ? 17 : 19
  #expect(try await fixture.execute())
  #expect(fixture.events == [.lookup, .frontmost] + (alreadyFrontmost ? [] : [.activate(17)])
    + [.pick(17, TargetFixture.tokens)])
}

@MainActor
@Test func menuBarReresolvesAfterLaunchAndWaitsForRegistration() async throws {
  let fixture = TargetFixture()
  fixture.frontmost = 19
  fixture.onSleep = { fixture.running = [17, 18] }
  defer { fixture.onSleep = nil }
  #expect(try await fixture.execute())
  #expect(fixture.events == [
    .lookup, .launch("/Applications/Example.app"), .lookup, .sleep(.milliseconds(100)),
    .lookup, .frontmost, .activate(17), .pick(17, TargetFixture.tokens),
  ])
}

@MainActor
@Test func menuBarRegistrationPollingStopsAtDeadline() async throws {
  let fixture = TargetFixture()
  await #expect(throws: MenuBar.TargetError.launchRegistrationTimedOut) {
    try await fixture.execute()
  }
  #expect(fixture.events == [.lookup, .launch("/Applications/Example.app")]
    + Array(repeating: [.lookup, .sleep(.milliseconds(100))], count: 10).flatMap { $0 })
}

@MainActor
@Test func menuBarDoesNotPickAfterLaunchOrActivationFailure() async throws {
  let fixture = TargetFixture()
  fixture.launchFailure = true
  await #expect(throws: TargetFixture.Failure.launch) {
    try await fixture.execute()
  }
  #expect(fixture.events == [.lookup, .launch("/Applications/Example.app")])

  fixture.events = []
  fixture.running = [17]
  fixture.activationSucceeds = false
  await #expect(throws: MenuBar.TargetError.activationFailed(processIdentifier: 17)) {
    try await fixture.execute()
  }
  #expect(fixture.events == [.lookup, .frontmost, .activate(17)])
}

@MainActor
@Test func menuBarRegistrationChecksCancellationEvenWhenSleepReturnsNormally() async throws {
  let fixture = TargetFixture()
  fixture.onSleep = { withUnsafeCurrentTask { $0?.cancel() } }
  let task = Task { try await fixture.execute() }
  await #expect(throws: CancellationError.self) { try await task.value }
  #expect(fixture.events == [.lookup, .launch("/Applications/Example.app"), .lookup, .sleep(.milliseconds(100))])
}

@MainActor
@Test func menuBarRejectsEmptyTokensBeforeWorkspaceEffects() async throws {
  let fixture = TargetFixture()
  await #expect(throws: MenuBar.ExecutionError.emptyTokens) { try await fixture.execute(tokens: []) }
  #expect(fixture.events.isEmpty)
}

@MainActor
private final class TargetFixture {
  enum Failure: Error { case launch }
  enum Event: Equatable {
    case lookup
    case frontmost
    case launch(String)
    case activate(Int32)
    case sleep(Duration)
    case pick(Int32, [MenuBar.Token])
  }

  static let tokens: [MenuBar.Token] = [.menuItem(name: "File"), .menuItem(name: "New Window")]
  var events: [Event] = []
  var frontmost: Int32?
  var running: [Int32] = []
  var launchFailure = false
  var activationSucceeds = true
  var pickResult = true
  var onSleep: (() -> Void)?
  private var instant = ContinuousClock.now

  func execute(explicit: Bool = true, tokens: [MenuBar.Token] = tokens) async throws -> Bool {
    let command = Command.MenuBar(
      application: explicit ? .init(bundleIdentifier: "com.example.app", bundleName: "Example",
                                    path: "/Applications/Example.app") : nil,
      tokens: tokens,
    )
    return try await MenuBar.execute(
      command,
      workspace: .init(
        frontmost: {
          self.events.append(.frontmost)
          return self.frontmost
        },
        firstRunning: { identifier in
          #expect(identifier == "com.example.app")
          self.events.append(.lookup)
          return self.running.first
        },
        launch: { url in
          self.events.append(.launch(url.path))
          if self.launchFailure { throw Failure.launch }
        },
        activate: { pid in
          self.events.append(.activate(pid))
          return self.activationSucceeds
        },
      ),
      now: { self.instant },
      sleep: { until in
        self.events.append(.sleep(self.instant.duration(to: until)))
        self.instant = until
        self.onSleep?()
      },
      pick: { tokens, pid in
        self.events.append(.pick(pid, tokens))
        return self.pickResult
      },
    )
  }
}
