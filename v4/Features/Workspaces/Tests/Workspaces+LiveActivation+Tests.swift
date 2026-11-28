import AccessibilitySystem
import AppKit
import ApplicationCatalog
import ApplicationServices
import ApplicationsFeature
import Commands
import SystemFeature
import Testing
import UserSpace
import WindowTilingFeature
import WorkspacesFeature

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"] != nil))
@MainActor func liveWorkspaceActivation() async throws {
  try await checkWorkspaceActivation(effects: false)
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WORKSPACES_EFFECTS"] == "1"))
@MainActor func liveWorkspaceEffects() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the terminal running the Workspace effects smoke.")
  try await checkWorkspaceActivation(effects: true)
}

@MainActor
private func checkWorkspaceActivation(effects: Bool) async throws {
  let directory = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"]))
  let apps: [ApplicationCatalog.Application] = ["A", "B"].map { name in
    .init(bundleIdentifier: "com.zenangst.kc-workspace-fixture-\(name.lowercased())",
          bundleName: "Workspace Fixture \(name)", path: directory.appendingPathComponent("Workspace Fixture \(name).app").path)
  }
  for app in apps {
    try #require(Bundle(path: app.path)?.bundleIdentifier == app.bundleIdentifier)
    try #require(NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier).isEmpty)
  }
  defer {
    for app in apps {
      let path = URL(fileURLWithPath: app.path).resolvingSymlinksInPath()
      for running in NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
        where running.bundleURL?.resolvingSymlinksInPath().path == path.path {
        _ = running.terminate()
      }
    }
  }

  let application = ApplicationsFeature.Application.Executor(.production)
  let accessibility = AccessibilitySystem.Client()
  var verifiedEffects: [String] = []
  func fixtureProcess(_ index: Int) throws -> NSRunningApplication {
    let app = apps[index]
    let path = URL(fileURLWithPath: app.path).resolvingSymlinksInPath().path
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
    try #require(running.count == 1)
    let process = try #require(running.first)
    try #require(process.bundleURL?.resolvingSymlinksInPath().path == path)
    return process
  }
  func waitForFrontmost(_ bundleIdentifier: String) async throws {
    let deadline = ContinuousClock.now + .seconds(4)
    while NSWorkspace.shared.frontmostApplication?.bundleIdentifier != bundleIdentifier,
          ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(100))
    }
    try #require(NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier,
                 "Expected \(bundleIdentifier) to become frontmost.")
  }
  let executor = Workspaces.Executor<UserSpace.Snapshot>(
    captureSnapshot: { .init(apps: .init()) },
    runChild: { step, snapshot in
      if effects, case .hideAllApps = step {
        let a = try fixtureProcess(0)
        let b = try fixtureProcess(1)
        try #require(!a.isHidden && !b.isHidden)
        try await SystemCommand.hideAllApps(
          workflowApplications: [.init(application: apps[1])],
          limitingTo: [a.processIdentifier, b.processIdentifier],
        )
        try #require(a.isHidden && !a.isTerminated && !b.isHidden)
        try #require(NSWorkspace.shared.frontmostApplication == b)
        verifiedEffects.append("hide")
        return
      }
      guard case let .application(command) = step, apps.contains(command.application) else {
        Issue.record("Smoke can only dispatch the two fixture applications")
        return
      }
      let request = Command.Application(
        name: command.name, action: command.action, application: command.application,
        modifiers: Array(command.modifiers),
      )
      try await application.execute(request, cgEventType: nil, snapshot: snapshot)
      if effects {
        // App launch can return before macOS delivers activation. The Fill
        // adapter requires the exact fixture to be frontmost before touching AX.
        try await waitForFrontmost(command.application.bundleIdentifier)
      }
    },
    runTiling: { kind, _ in
      try #require(effects && kind == .fill)
      let target = try fixtureProcess(1)
      try #require(NSWorkspace.shared.frontmostApplication == target)
      let pid = target.processIdentifier
      let (id, before) = try await accessibility.withApplication(processIdentifier: pid) { session in
        let window = try #require(try session.focusedWindow())
        return (try #require(try session.windowIDCandidate(for: window)), try session.frame(of: window))
      }
      try #require(abs(before.width - 420) <= 1, "Fixture window must start untiled.")
      try #require(try await WindowTiling.execute(.fill, onFocusedWindow: id, of: target, using: accessibility))
      let primary = try #require(NSScreen.screens.first)
      let screen = try #require(NSScreen.screens.first { screen in
        let frame = screen.frame
        return CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
          .contains(CGPoint(x: before.midX, y: before.midY))
      })
      let frame = screen.visibleFrame
      let visible = CGRect(x: frame.minX, y: primary.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
      var after = before
      for _ in 0 ..< 20 {
        after = try await accessibility.withApplication(processIdentifier: pid) { session in
          let window = try #require(try session.focusedWindow())
          try #require(try session.windowIDCandidate(for: window) == id)
          return try session.frame(of: window)
        }
        if WindowTiling.classify(after, in: visible, margin: 8) == .fill { break }
        try await Task.sleep(for: .milliseconds(100))
      }
      try #require(after.width > before.width && WindowTiling.classify(after, in: visible, margin: 8) == .fill,
                   "The exact fixture window must settle in Fill.")
      verifiedEffects.append("fill")
    },
  )
  let a = Workspaces.SavedWorkspace(id: "a", applications: [.init(apps[0].bundleIdentifier)])
  let b = Workspaces.SavedWorkspace(id: "b", applications: [.init(apps[1].bundleIdentifier)],
                                    tiling: effects ? .fill : nil, hideOtherApps: effects)
  let snapshot = UserSpace.Snapshot(apps: .init())
  func activateAndCheck(_ workspace: Workspaces.SavedWorkspace, returning: Bool = false) async throws {
    let input = Workspaces.ActivationInput(catalog: apps)
    let outcome = if returning {
      try await executor.activatePrevious(input: input, parentSnapshot: snapshot)
    } else {
      try await executor.activate(workspace, input: input, parentSnapshot: snapshot)
    }
    try #require(outcome == .completed)
    let expected = try #require(workspace.applications.first?.bundleIdentifier)
    try await waitForFrontmost(expected)
  }

  try await activateAndCheck(a)
  try await activateAndCheck(b)
  #expect(executor.current == b && executor.previous == a)
  if effects {
    #expect(verifiedEffects == ["fill", "hide"])
    return
  }
  try await activateAndCheck(a, returning: true)
  #expect(executor.current == a && executor.previous == b)
}
