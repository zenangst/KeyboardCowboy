import Commands
import Foundation
@testable import SystemFeature
import Testing
import UserSpace

@MainActor
private func command(_ id: String, _ action: Command.Application.Action) -> Command.Application {
  Command.Application(action: action, application: .init(bundleIdentifier: id, bundleName: id, path: "/\(id).app"))
}

@MainActor
private final class Fixture {
  typealias HideAllApps = SystemFeature.Operation.HideAllApps
  static let main = CGRect(x: 0, y: 0, width: 1000, height: 800)
  static let other = main.offsetBy(dx: -1000, dy: 0)
  var frames = [main, other]
  var apps: [HideAllApps.Application] = []
  var inventory: [HideAllApps.Window] = []
  var hidden: Set<Int32> = []
  var calls: [Int32] = []
  var pauses = 0
  var inventoryReads = 0
  var onPause: () throws -> Void = {}

  func add(_ pid: Int32, _ id: String?, path: String = "/Example.app", regular: Bool = true,
           frame: CGRect = CGRect(x: 10, y: 10, width: 400, height: 300), alpha: Double = 1,
           owner: String = "Example", windowID: Int = 1) {
    apps.append(.init(pid: pid, bundleID: id, bundleURL: URL(filePath: path), isRegular: regular,
                      isHidden: { self.hidden.contains(pid) }, hide: { self.calls.append(pid) }))
    inventory.append(.init(id: windowID, pid: pid, owner: owner, frame: frame, alpha: alpha))
  }

  func run(_ commands: [Command.Application] = []) async throws {
    let operation = HideAllApps(screens: { self.frames }, applications: { self.apps }, windows: {
      self.inventoryReads += 1
      return self.inventory.filter { !self.hidden.contains($0.pid) }
    }, ownBundleID: "self", ownPID: 99, pause: {
      self.pauses += 1
      try self.onPause()
    })
    try await operation(commands)
  }
}

@Test @MainActor func hidesOnlyEligibleAppsOnTheLastTargetDisplay() async throws {
  let fixture = Fixture()
  let other = CGRect(x: -990, y: 10, width: 400, height: 300)
  fixture.add(1, "main")
  fixture.add(2, "target", frame: other)
  fixture.add(3, "keep-open", frame: other)
  fixture.add(4, "keep-unhide", frame: other)
  fixture.add(5, "eligible", frame: other)
  fixture.add(6, "accessory", regular: false, frame: other)
  fixture.add(7, "framework", path: "/Example.app/Contents/Frameworks/Helper.app", frame: other)
  fixture.add(8, "non-app", path: "/Example", frame: other)
  fixture.add(9, "translucent", frame: other, alpha: 0.5)
  fixture.add(10, "system-window", frame: other, owner: "WindowManager")
  fixture.add(11, "tiny", frame: CGRect(x: -990, y: 10, width: 300, height: 300))
  fixture.add(12, "self", frame: other)
  fixture.add(13, "already-hidden", frame: other)
  fixture.add(14, "invalid-window", frame: other, windowID: 0)
  fixture.add(99, nil, frame: other)
  fixture.hidden = [13]
  fixture.onPause = { [weak fixture] in fixture?.hidden.insert(5) }

  try await fixture.run([command("keep-open", .open), command("keep-unhide", .unhide), command("target", .close)])

  #expect(fixture.calls == [5])
  #expect(fixture.pauses == 1) // Protected or unrelated windows do not hold up completion.
}

@Test(arguments: [true, false])
@MainActor func finderIsHiddenFirstOnlyForUnhideOnlyWorkflows(unhideOnly: Bool) async throws {
  let fixture = Fixture()
  fixture.add(1, "other")
  fixture.add(2, "com.apple.finder", frame: .zero)
  fixture.add(3, "target")
  fixture.onPause = { [weak fixture] in fixture?.hidden.insert(1) }

  try await fixture.run([command("target", unhideOnly ? .unhide : .open)])

  #expect(fixture.calls == (unhideOnly ? [2, 1] : [1]))
}

@Test @MainActor func hideAllAppsIsANoOpWithoutScreensAndBoundsUnsuccessfulHides() async throws {
  let fixture = Fixture()
  fixture.add(1, "other")
  fixture.frames = []
  try await fixture.run([command("target", .unhide)])
  #expect(fixture.calls.isEmpty)
  #expect(fixture.inventoryReads == 0)

  fixture.frames = [Fixture.main]
  try await fixture.run()
  #expect(fixture.calls == [1])
  #expect(fixture.pauses == 110)
}

@Test @MainActor func cancellationDuringHideWaitDoesNotHideTheNextApp() async {
  let fixture = Fixture()
  fixture.add(1, "first")
  fixture.add(2, "second")
  fixture.onPause = {
    withUnsafeCurrentTask { $0?.cancel() }
  }
  let task = Task { @MainActor in try await fixture.run() }
  await #expect(throws: CancellationError.self) { try await task.value }
  #expect(fixture.calls == [1])
}

@Test @MainActor func dispatchesHideAllAppsWithOrderedWorkflowContext() async throws {
  let action = try JSONDecoder().decode(SystemCommand.Action.self, from: Data(#""hideAllApps""#.utf8))
  var requests: [[String]] = []
  let executor = SystemCommand.Executor(
    sendDockNotification: { _ in Issue.record("Unexpected Dock notification") },
    previousApplication: {
      Issue.record("Unexpected snapshot")
      return (nil, UserSpace.Snapshot(apps: .init()))
    },
    openApplication: { _, _, _ in Issue.record("Unexpected application open") },
    hideAllApps: { requests.append($0.map(\.application.bundleIdentifier)) },
  )
  #expect(try await executor.run(action, workflowApplications: [command("first", .open), command("last", .hide)]) == .invoked)
  #expect(requests == [["first", "last"]])
}
