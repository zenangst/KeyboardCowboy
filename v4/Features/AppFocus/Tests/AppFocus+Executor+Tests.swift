import AppFocusFeature
import ApplicationCatalog
import CoreGraphics
import Testing
import WindowTilingFeature

private let app = ApplicationCatalog.Application(bundleIdentifier: "target", bundleName: "Target", path: "/Target.app")
private let target = AppFocus.Snapshot.Process(bundleIdentifier: "target", pid: 42)
private let other = AppFocus.Snapshot.Process(bundleIdentifier: "other", pid: 43)

private func window(_ id: CGWindowID, owner: pid_t = 42, onScreen: Bool = true) -> AppFocus.Window {
  .init(id: id, owner: owner, frame: CGRect(x: 0, y: 0, width: 400, height: 300), isOnScreen: onScreen)
}

@Test(arguments: [true, false])
@MainActor func currentWildcardOpensOnlyWhenRequestedIfAWindowAlreadyExists(createNew: Bool) async throws {
  var calls: [String] = []
  let executor = AppFocus.Executor(
    snapshot: { .init(frontmost: target, running: [target], windows: [window(1)]) },
    open: { #expect($0 == app); calls.append("open") },
    activateAll: { #expect($0 == target); calls.append("activate") },
    hideOtherApps: { #expect($0 == target); calls.append("hide") },
    tile: { action, process in #expect(action == .fill && process == target); calls.append("tile") },
  )
  let result = try await executor.run(
    .init(bundleIdentifier: "*.*.current", createNewWindow: createNew, hideOtherApps: true, tiling: .arrangeLeftRight),
    catalog: [], current: app,
  )
  #expect(result == .completed)
  #expect(calls == (createNew ? ["open", "activate", "hide", "tile"] : ["activate", "hide", "tile"]))
}

@Test @MainActor func previousWildcardOpensForZeroEligibleWindowsAndWaitsForItsOwnPID() async throws {
  var state = AppFocus.Snapshot(frontmost: other, running: [target, other],
                                windows: [window(1, owner: 43), window(2, onScreen: false)])
  var calls: [String] = []
  let executor = AppFocus.Executor(
    snapshot: { state },
    open: { #expect($0 == app); calls.append("open") },
    activateAll: { #expect($0 == target); calls.append("activate") },
    hideOtherApps: { _ in Issue.record("Unexpected hide") },
    tile: { action, process in #expect(action == .center && process == target); calls.append("tile") },
    sleep: { interval in
      if interval == .milliseconds(10) {
        calls.append("wait activation")
        state = .init(frontmost: target, running: [target, other], windows: [window(1, owner: 43)])
      } else {
        #expect(interval == .milliseconds(50))
        calls.append("wait window")
        state = .init(frontmost: target, running: [target, other], windows: [window(3)])
      }
    },
  )
  let result = try await executor.run(
    .init(bundleIdentifier: "*.*.previous", createNewWindow: false, tiling: .center),
    catalog: [], previous: app,
  )
  #expect(result == .completed)
  #expect(calls == ["open", "activate", "wait activation", "wait window", "tile"])
}

@Test(arguments: [false, true])
@MainActor func timeoutsAreBoundedAndDoNotTouchUnrelatedWindows(activated: Bool) async throws {
  var delays: [Duration] = []
  let executor = AppFocus.Executor(
    snapshot: { .init(frontmost: activated ? target : other, running: [target, other], windows: [window(1, owner: 43)]) },
    open: { _ in },
    activateAll: { _ in },
    hideOtherApps: { _ in Issue.record("Unexpected hide") },
    tile: { _, _ in Issue.record("Unexpected tiling") },
    sleep: { delays.append($0) },
  )
  let result = try await executor.run(.init(bundleIdentifier: "target", hideOtherApps: true, tiling: .fill), catalog: [app])
  #expect(result == (activated ? .noEligibleWindows : .activationTimedOut))
  #expect(delays == Array(repeating: .milliseconds(activated ? 50 : 10), count: 10))
}

@Test(arguments: [false, true])
@MainActor func aerospaceSuppressesLayoutAndFocusChangeAfterHidePreventsTiling(aerospace: Bool) async throws {
  var frontmost = target
  var opened = false
  var hidden = false
  let executor = AppFocus.Executor(
    snapshot: {
      let running = aerospace ? [target, .init(bundleIdentifier: "bobko.aerospace", pid: 77)] : [target]
      return .init(frontmost: frontmost, running: running, windows: opened ? [window(1)] : [])
    },
    open: { _ in opened = true },
    activateAll: { _ in },
    hideOtherApps: { _ in hidden = true; frontmost = other },
    tile: { _, _ in Issue.record("Unexpected tiling") },
  )
  let result = try await executor.run(.init(bundleIdentifier: "target", hideOtherApps: true, tiling: .fill), catalog: [app])
  #expect(opened)
  #expect(hidden != aerospace)
  #expect(result == (aerospace ? .completed : .focusChanged))
}

@Test @MainActor func missingTargetAndCancelledWaitDoNotRunLayoutEffects() async throws {
  let executor = AppFocus.Executor(
    snapshot: { .init(frontmost: other) }, open: { _ in }, activateAll: { _ in },
    hideOtherApps: { _ in Issue.record("Unexpected hide") },
    tile: { _, _ in Issue.record("Unexpected tiling") },
    sleep: { _ in throw CancellationError() },
  )
  #expect(try await executor.run(.init(bundleIdentifier: "*.*.previous"), catalog: [app]) == .unavailableApplication)
  await #expect(throws: CancellationError.self) {
    try await executor.run(.init(bundleIdentifier: "target", hideOtherApps: true, tiling: .fill), catalog: [app])
  }
}

@Test @MainActor func relaunchedProcessDoesNotInheritTheActivatedTargetsLayout() async throws {
  var state = AppFocus.Snapshot(frontmost: target, running: [target])
  let replacement = AppFocus.Snapshot.Process(bundleIdentifier: target.bundleIdentifier, pid: 84)
  let executor = AppFocus.Executor(
    snapshot: { state }, open: { _ in }, activateAll: { _ in },
    hideOtherApps: { _ in Issue.record("Unexpected hide after PID change") },
    tile: { _, _ in Issue.record("Unexpected tiling after PID change") },
    sleep: { interval in
      #expect(interval == .milliseconds(50))
      state = .init(frontmost: replacement, running: [replacement], windows: [window(1, owner: 84)])
    },
  )
  let result = try await executor.run(.init(bundleIdentifier: "target", hideOtherApps: true, tiling: .fill), catalog: [app])
  #expect(result == .focusChanged)
}
