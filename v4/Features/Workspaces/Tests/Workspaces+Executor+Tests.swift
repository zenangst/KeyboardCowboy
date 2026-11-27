import ApplicationCatalog
import Testing
@testable import WorkspacesFeature

private typealias Executor = Workspaces.Executor<Int>

private func catalog(_ ids: String...) -> [ApplicationCatalog.Application] {
  ids.map { .init(bundleIdentifier: $0, bundleName: $0, path: "/Applications/\($0).app") }
}

@Test @MainActor func activationRunsInOrderWithFreshChildSnapshotsAndDirectTiling() async throws {
  var calls: [String] = []
  var snapshot = 0
  var membership = Workspaces.Membership()
  membership.assign("dynamic", to: "layout", stageManagerEnabled: false)
  let executor = Executor(
    captureSnapshot: {
      snapshot += 1
      calls.append("capture:\(snapshot)")
      return snapshot
    },
    runChild: { step, snapshot in
      switch step {
      case .application(let application): calls.append("\(application.application.bundleIdentifier):\(snapshot)")
      case .hideAllApps: calls.append("hide:\(snapshot)")
      case .tiling: Issue.record("Tiling must bypass child dispatch")
      }
    },
    runTiling: { kind, snapshot in
      #expect(kind == .fill)
      calls.append("fill:\(snapshot)")
    },
    resetFocus: { calls.append("reset") },
    sleep: { duration in
      #expect(duration == .milliseconds(40))
      calls.append("delay")
    },
  )
  let workspace = Workspaces.SavedWorkspace(id: "layout", applications: [.init("static")], tiling: .fill, hideOtherApps: true)
  let result = try await executor.activate(
    workspace, input: .init(catalog: catalog("static", "dynamic"), membership: membership), parentSnapshot: 99,
  )
  #expect(result == .completed)
  #expect(executor.current == workspace && executor.previous == nil)
  #expect(calls == ["capture:1", "dynamic:1", "capture:2", "static:2", "fill:99",
                    "capture:3", "hide:3", "delay", "reset"])
}

@Test @MainActor func previousWorkspacePreservesSameIDHistoryAndSkipsTilingOnReturn() async throws {
  var actions: [String] = []
  var tilings: [Workspaces.Tiling] = []
  let executor = Executor(
    captureSnapshot: { 0 },
    runChild: { step, _ in
      if case let .application(application) = step { actions.append(application.action.rawValue) }
    },
    runTiling: { kind, _ in tilings.append(kind) },
  )
  let a = Workspaces.SavedWorkspace(id: "a", applications: [.init("one"), .init("two")], tiling: .center)
  let b = Workspaces.SavedWorkspace(id: "b", applications: [.init("one")])
  let editedB = Workspaces.SavedWorkspace(id: "b", applications: [.init("two")])
  let input = Workspaces.ActivationInput(catalog: catalog("one", "two"))
  #expect(try await executor.activatePrevious(input: input, parentSnapshot: 0) == .noPreviousWorkspace)
  _ = try await executor.activate(a, input: input, parentSnapshot: 0)
  _ = try await executor.activate(b, input: input, parentSnapshot: 0)
  _ = try await executor.activate(editedB, input: input, parentSnapshot: 0)
  #expect(executor.previous == a)

  actions.removeAll()
  #expect(try await executor.activatePrevious(input: input, parentSnapshot: 0) == .completed)
  #expect(actions == ["unhide", "unhide"])
  #expect(tilings == [.center])
  #expect(executor.current == a && executor.previous == editedB)
}

@Test @MainActor func emptyStageCommitsHistoryWithoutDispatchOrReset() async throws {
  let executor = Executor(
    captureSnapshot: { Issue.record("Unexpected capture"); return 0 },
    runChild: { _, _ in Issue.record("Unexpected child") },
    runTiling: { _, _ in Issue.record("Unexpected tiling") },
    resetFocus: { Issue.record("Unexpected reset") },
  )
  let empty = Workspaces.SavedWorkspace(id: "empty")
  let result = try await executor.activate(empty, input: .init(catalog: [], stageManagerEnabled: true), parentSnapshot: 0)
  #expect(result == .emptyStage)
  #expect(executor.current == empty)
}

@Test(arguments: [false, true])
@MainActor func failedOrCancelledActivationKeepsHistoryAndStopsDispatch(cancelled: Bool) async {
  enum ProbeError: Error { case effect }
  var calls: [String] = []
  let executor = Executor(
    captureSnapshot: { 0 },
    runChild: { _, _ in
      calls.append("child")
      if cancelled { withUnsafeCurrentTask { $0?.cancel() } }
      throw ProbeError.effect
    },
    runTiling: { _, _ in Issue.record("Unexpected tiling") },
    resetFocus: { calls.append("reset") },
  )
  let workspace = Workspaces.SavedWorkspace(id: "target", applications: [.init("one"), .init("two")])
  let task = Task { @MainActor in
    try await executor.activate(workspace, input: .init(catalog: catalog("one", "two")), parentSnapshot: 0)
  }
  if cancelled {
    await #expect(throws: CancellationError.self) { try await task.value }
  } else {
    await #expect(throws: ProbeError.effect) { try await task.value }
  }
  #expect(executor.current == workspace)
  #expect(calls == (cancelled ? ["child", "reset"] : ["child"]))
}

@Test(arguments: [nil, "outside", "main"] as [String?])
@MainActor func focusFallbackReadsFreshStateAfterTheFinalChild(menuBarOwner: String?) async throws {
  var calls: [String] = []
  var captures = 0
  let executor = Executor(
    captureSnapshot: {
      captures += 1
      return captures
    },
    runChild: { step, snapshot in
      switch step {
      case .application(let app):
        calls.append("\(app.application.bundleIdentifier):\(app.action.rawValue):\(snapshot)")
        if snapshot == 3 { #expect(app.modifiers.isEmpty) }
      case .hideAllApps: calls.append("hide:\(snapshot)")
      case .tiling: Issue.record("Unexpected child")
      }
    },
    runTiling: { _, _ in calls.append("tile") },
    resetFocus: { calls.append("reset") },
    sleep: { calls.append($0 == .milliseconds(50) ? "settle" : "hide delay") },
    readFocusState: {
      calls.append("read focus")
      return .init(menuBarOwner: menuBarOwner, runningBundleIdentifiers: [])
    },
  )
  let workspace = Workspaces.SavedWorkspace(
    id: "layout", applications: [.init("main"), .init("optional", onlyWhenRunning: true)], tiling: .fill,
    hideOtherApps: true,
  )
  let input = Workspaces.ActivationInput(catalog: catalog("main", "optional"))
  _ = try await executor.activate(workspace, input: input, parentSnapshot: 0)
  let fallback = menuBarOwner == "outside" ? ["main:open:3"] : []
  #expect(calls == ["main:open:1", "tile", "hide:2", "settle", "read focus"] + fallback + ["hide delay", "reset"])
}

@Test @MainActor func terminalTilingSkipsFocusFallback() async throws {
  let executor = Executor(
    captureSnapshot: { 0 },
    runChild: { _, _ in },
    runTiling: { _, _ in },
    sleep: { _ in Issue.record("No fallback delay after direct tiling") },
    readFocusState: {
      Issue.record("No fallback read after direct tiling")
      return .init(menuBarOwner: "outside", runningBundleIdentifiers: [])
    },
  )
  _ = try await executor.activate(.init(id: "layout", tiling: .fill),
                                  input: .init(catalog: catalog("app"), membership: membershipForLayout()), parentSnapshot: 0)
}

private func membershipForLayout() -> Workspaces.Membership {
  var membership = Workspaces.Membership()
  membership.assign("app", to: "layout", stageManagerEnabled: false)
  return membership
}

@Test @MainActor func newerActivationCancelsDeferredIndexEvenIfSleepIgnoresCancellation() async throws {
  let (starts, signal) = AsyncStream<CheckedContinuation<Void, Never>>.makeStream()
  var waits = starts.makeAsyncIterator()
  var calls: [String] = []
  let executor = Executor(
    captureSnapshot: { 0 },
    runChild: { _, _ in },
    runTiling: { _, _ in },
    resetFocus: { calls.append("reset") },
    sleep: { duration in
      #expect(duration == .milliseconds(375))
      await withCheckedContinuation { signal.yield($0) }
    },
    indexTiling: { calls.append("index") },
  )

  let input = Workspaces.ActivationInput(catalog: [])
  _ = try await executor.activate(.init(id: "first"), input: input, parentSnapshot: 0)
  let first = try #require(executor.pendingIndex)
  let firstWait = await waits.next()
  _ = try await executor.activate(.init(id: "second"), input: input, parentSnapshot: 0)
  firstWait?.resume()
  await first.value
  #expect(first.isCancelled)
  #expect(calls == ["reset", "reset"])
  let second = try #require(executor.pendingIndex)
  let secondWait = await waits.next()
  secondWait?.resume()
  await second.value
  #expect(calls == ["reset", "reset", "index"])
}
