import ApplicationsFeature
import CowboyCore
import Foundation
import Testing

private actor StageFixture {
  typealias Stage = Application.StageOrchestrator
  var events: [String] = []
  var targets: [Stage.Target?]
  var ax: [[Stage.Window]]
  var snapshots: [Stage.Snapshot]
  var cancelOnReveal = false
  init(targets: [Stage.Target?], ax: [[Stage.Window]], snapshots: [Stage.Snapshot]) {
    self.targets = targets; self.ax = ax; self.snapshots = snapshots
  }
  func record(_ event: String) { events.append(event) }
  func nextTarget() -> Stage.Target? { events.append("target"); return targets.count > 1 ? targets.removeFirst() : targets[0] }
  func nextAX() -> [Stage.Window] { events.append("ax"); return ax.count > 1 ? ax.removeFirst() : ax[0] }
  func nextSnapshot() -> Stage.Snapshot { events.append("snapshot"); return snapshots.count > 1 ? snapshots.removeFirst() : snapshots[0] }
  func revealSleep() throws { events.append("sleep"); if cancelOnReveal { throw CancellationError() } }
  func setCancel() { cancelOnReveal = true }
  func effects() -> Stage.Effects {
    Stage.Effects(snapshot: { await self.nextSnapshot() }, target: { _ in await self.nextTarget() },
                  activateTarget: { _ in await self.record("activate") }, restoreFocus: { _ in await self.record("focus") },
                  unhide: { _ in await self.record("unhide") }, accessibilityWindows: { _ in await self.nextAX() },
                  pointer: { await self.record("pointer"); return CGPoint(x: 50, y: 50) },
                  movePointer: { p in await self.record("move \(Int(p.x))") },
                  shiftClick: { p in await self.record("click \(Int(p.x))") },
                  unminimizeAndRaise: { _ in await self.record("raise") }, sleep: { _ in try await self.revealSleep() })
  }
}

private actor StageTestGate {
  private var waiting: CheckedContinuation<Void, Never>?
  private var released = false
  func wait() async {
    guard !released else { return }
    await withCheckedContinuation { waiting = $0 }
  }
  func release() {
    released = true
    waiting?.resume()
    waiting = nil
  }
}

private func stageCommand() throws -> Command.Application {
  try JSONDecoder().decode(Command.Application.self, from: Data(#"{"application":{"bundleIdentifier":"example.target","bundleName":"Target","path":"/Target.app"},"action":"open","meta":{"id":"id","name":"Open","enabled":true}}"#.utf8))
}
private func stageWindow(_ x: CGFloat, id: UInt32 = 1) -> Application.StageOrchestrator.Window {
  .init(id: id, frame: CGRect(x: x, y: 10, width: 100, height: 100))
}
private func stageSnapshot(_ windows: [Application.StageOrchestrator.Window]) -> Application.StageOrchestrator.Snapshot {
  .init(frontmost: "original", windows: windows, screen: CGRect(x: 0, y: 0, width: 1000, height: 800))
}

@Test(arguments: [-50, 1050]) func stageRevealsAndRestoresPointer(x: Int) async throws {
  let fixture = StageFixture(targets: [.init(hidden: false)], ax: [[stageWindow(300)]], snapshots: [stageSnapshot([stageWindow(CGFloat(x))]), stageSnapshot([stageWindow(20)])])
  let stage = await Application.StageOrchestrator(effects: fixture.effects())
  #expect(try await stage.execute(stageCommand()))
  let edge = x < 0 ? 0 : 999
  #expect(await fixture.events == ["snapshot", "target", "ax", "pointer", "move \(edge)", "sleep", "snapshot", "click 32", "raise", "move 50"])
}

@Test func stageStartsUnhidesAndFindsWindow() async throws {
  let fixture = StageFixture(targets: [nil, nil, .init(hidden: true), .init(hidden: true), .init(hidden: false)], ax: [[], [stageWindow(300)]], snapshots: [stageSnapshot([]), stageSnapshot([]), stageSnapshot([]), stageSnapshot([stageWindow(30)])])
  let stage = await Application.StageOrchestrator(effects: fixture.effects(), attempts: 3)
  #expect(try await stage.execute(stageCommand()))
  #expect(await fixture.events == ["snapshot", "target", "activate", "focus", "target", "sleep", "target", "focus", "snapshot", "unhide", "target", "sleep", "target", "snapshot", "ax", "activate", "focus", "ax", "focus", "sleep", "snapshot", "pointer", "click 42", "raise", "move 50"])
}

@Test func stageDeclinesAlreadyPresentAndMissingWindow() async throws {
  for windows in [[stageWindow(300)], [stageWindow(10, id: 2)]] {
    let fixture = StageFixture(targets: [.init(hidden: false)], ax: [[stageWindow(300)]], snapshots: [stageSnapshot(windows)])
    let stage = await Application.StageOrchestrator(effects: fixture.effects())
    #expect(try await !stage.execute(stageCommand()))
    #expect(await fixture.events == ["snapshot", "target", "ax"])
  }
}

@Test func stageTimeoutIsBounded() async throws {
  let fixture = StageFixture(targets: [nil], ax: [[]], snapshots: [stageSnapshot([])])
  let stage = await Application.StageOrchestrator(effects: fixture.effects(), attempts: 2)
  await #expect(throws: Application.StageOrchestrator.Failure.timedOut) { try await stage.execute(stageCommand()) }
  #expect(await fixture.events == ["snapshot", "target", "activate", "focus", "target", "sleep", "target", "focus"])
}

@Test func stageRestoresPointerOnCancellationAndMissingRefreshedWindow() async throws {
  for cancel in [true, false] {
    let fixture = StageFixture(targets: [.init(hidden: false)], ax: [[stageWindow(300)]], snapshots: [stageSnapshot([stageWindow(-50)]), stageSnapshot([])])
    if cancel { await fixture.setCancel() }
    let stage = await Application.StageOrchestrator(effects: fixture.effects())
    do { _ = try await stage.execute(stageCommand()); Issue.record("Expected failure") }
    catch { if cancel { #expect(error is CancellationError) } else { #expect(error as? Application.StageOrchestrator.Failure == .windowDisappeared) } }
    let expected = cancel ? ["snapshot", "target", "ax", "pointer", "move 0", "sleep", "move 50"] : ["snapshot", "target", "ax", "pointer", "move 0", "sleep", "snapshot", "move 50"]
    #expect(await fixture.events == expected)
  }
}

@Test func stageDoesNotClickThumbnailStillOutsideScreen() async throws {
  let fixture = StageFixture(targets: [.init(hidden: false)], ax: [[stageWindow(300)]],
                             snapshots: [stageSnapshot([stageWindow(-150)]), stageSnapshot([stageWindow(-150)])])
  let stage = await Application.StageOrchestrator(effects: fixture.effects())
  await #expect(throws: Application.StageOrchestrator.Failure.windowNotVisible) {
    try await stage.execute(stageCommand())
  }
  #expect(await fixture.events == ["snapshot", "target", "ax", "pointer", "move 0", "sleep", "snapshot", "move 50"])
}

@Test func stageUsesVisibleThumbnailAreaOnNonPrimaryScreen() async throws {
  let screen = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
  let outside = Application.StageOrchestrator.Window(id: 1, frame: CGRect(x: 20, y: 10, width: 100, height: 100))
  let revealed = Application.StageOrchestrator.Window(id: 1, frame: CGRect(x: -3, y: 10, width: 2, height: 100))
  let fixture = StageFixture(targets: [.init(hidden: false)], ax: [[stageWindow(300)]], snapshots: [
    .init(frontmost: "original", windows: [outside], screen: screen),
    .init(frontmost: "original", windows: [revealed], screen: screen),
  ])
  let stage = await Application.StageOrchestrator(effects: fixture.effects())
  #expect(try await stage.execute(stageCommand()))
  #expect(await fixture.events == ["snapshot", "target", "ax", "pointer", "move -1", "sleep", "snapshot", "click -2", "raise", "move 50"])
}

@Test func cancelledStageRestoresPointerAndRejectsConcurrentExecution() async throws {
  let fixture = StageFixture(targets: [.init(hidden: false)], ax: [[stageWindow(300)]],
                             snapshots: [stageSnapshot([stageWindow(-50)])])
  let gate = StageTestGate()
  let (events, continuation) = AsyncStream<String>.makeStream()
  var effects = await fixture.effects()
  effects.sleep = { _ in
    continuation.yield("sleep")
    await gate.wait()
  }
  let stage = Application.StageOrchestrator(effects: effects)
  let command = try stageCommand()

  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      do { _ = try await stage.execute(command); return false }
      catch is CancellationError { return true }
      catch { return false }
    }
    var iterator = events.makeAsyncIterator()
    #expect(await iterator.next() == "sleep")
    await #expect(throws: Application.StageOrchestrator.Failure.alreadyRunning) {
      try await stage.execute(command)
    }
    group.cancelAll()
    await gate.release()
    return await group.next() ?? false
  }
  continuation.finish()
  #expect(cancelled)
  #expect(await fixture.events == ["snapshot", "target", "ax", "pointer", "move 0", "move 50"])
}

@Test func stageCancellationTakesPrecedenceOverEffectFailure() async throws {
  let fixture = StageFixture(targets: [nil], ax: [[]], snapshots: [stageSnapshot([])])
  var effects = await fixture.effects()
  effects.target = { _ in
    withUnsafeCurrentTask { $0?.cancel() }
    throw NSError(domain: "test", code: 42)
  }
  let stage = Application.StageOrchestrator(effects: effects)
  let command = try stageCommand()
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      do { _ = try await stage.execute(command); return false }
      catch is CancellationError { return true }
      catch { return false }
    }
    return await group.next() ?? false
  }
  #expect(cancelled)
  #expect(await fixture.events == ["snapshot"])
}
