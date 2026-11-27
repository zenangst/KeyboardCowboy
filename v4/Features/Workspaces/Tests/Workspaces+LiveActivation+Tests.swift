import AppKit
import ApplicationCatalog
import ApplicationsFeature
import Commands
import Testing
import UserSpace
import WorkspacesFeature

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_WORKSPACES_FIXTURES"] != nil))
@MainActor func liveWorkspaceActivation() async throws {
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
  let executor = Workspaces.Executor<UserSpace.Snapshot>(
    captureSnapshot: { .init(apps: .init()) },
    runChild: { step, snapshot in
      guard case let .application(command) = step, apps.contains(command.application) else {
        Issue.record("Smoke can only dispatch the two fixture applications")
        return
      }
      let request = Command.Application(
        name: command.name, action: command.action, application: command.application,
        modifiers: Array(command.modifiers),
      )
      try await application.execute(request, cgEventType: nil, snapshot: snapshot)
    },
    runTiling: { _, _ in Issue.record("Unexpected tiling in the activation smoke") },
  )
  let a = Workspaces.SavedWorkspace(id: "a", applications: [.init(apps[0].bundleIdentifier)])
  let b = Workspaces.SavedWorkspace(id: "b", applications: [.init(apps[1].bundleIdentifier)])
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
    let deadline = ContinuousClock.now + .seconds(4)
    while NSWorkspace.shared.frontmostApplication?.bundleIdentifier != expected, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(100))
    }
    try #require(NSWorkspace.shared.frontmostApplication?.bundleIdentifier == expected)
  }

  try await activateAndCheck(a)
  try await activateAndCheck(b)
  #expect(executor.current == b && executor.previous == a)
  try await activateAndCheck(a, returning: true)
  #expect(executor.current == a && executor.previous == b)
}
