@testable import ApplicationsFeature
@testable import CowboyCore
import Foundation
import Testing

private func hideUnhideCommand(_ action: String, identifier: String = "example.target") throws -> Command.Application {
  let fixture = #"{"application":{"bundleIdentifier":"\#(identifier)","bundleName":"Target","path":"/Applications/Target.app"},"action":"\#(action)","meta":{"id":"saved-command","name":"Target","enabled":true}}"#
  return try JSONDecoder().decode(Command.Application.self, from: Data(fixture.utf8))
}

@Test(arguments: [true, false]) @MainActor
func executorHideOrdersLiveActivationBeforeTargetHide(hideSucceeds: Bool) async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let live = Core.RunningApplication(.testing(.init("example.live")))
  let stale = Core.RunningApplication(.testing(.init("example.stale")))
  let snapshot = UserSpace.Snapshot(apps: .init(frontMost: .init(bundleIdentifier: .init("example.stale"), runningApplication: stale)))
  let (events, trace) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, willExecute: { _ in trace.yield("hook") })

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: live)) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { requested in
        trace.yield(requested == identifier ? "lookup target" : "lookup unexpected")
        return [target]
      },
      onHide: { app in trace.yield(app === target ? "hide target" : "hide unexpected"); return hideSucceeds },
      onActivate: { app, options in
        trace.yield(app === live && options == [] ? "activate live" : "activate unexpected")
        return false
      }
    )) {
      let result = try await executor.execute(hideUnhideCommand("hide"), cgEventType: nil, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
  trace.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["hook", "lookup target", "activate live", "hide target"])
}

@Test(arguments: [true, false]) @MainActor
func executorUnhideOrdersLookupAndUnhideWithoutActivation(unhideSucceeds: Bool) async throws {
  let identifier = Core.BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let frontmost = Core.RunningApplication(.testing(.init("example.frontmost")))
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, trace) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, willExecute: { _ in trace.yield("hook") })

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: frontmost)) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { requested in
        trace.yield(requested == identifier ? "lookup target" : "lookup unexpected")
        return [target]
      },
      onHide: { _ in trace.yield("hide unexpected"); return true },
      onUnhide: { app in trace.yield(app === target ? "unhide target" : "unhide unexpected"); return unhideSucceeds },
      onActivate: { _, _ in trace.yield("activate unexpected"); return true }
    )) {
      let result = try await executor.execute(hideUnhideCommand("unhide"), cgEventType: nil, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
  trace.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["hook", "lookup target", "unhide target"])
}

@Test(arguments: ["hide", "unhide"]) @MainActor
func executorMissingHideUnhideTargetStopsAfterLookup(action: String) async throws {
  let snapshot = UserSpace.Snapshot(apps: .init())
  let (events, trace) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, willExecute: { _ in trace.yield("hook") })

  try await Core.Workspace.Testing.$mock.withValue(.init(frontmostApplication: .init(.testing(.init("example.frontmost"))))) {
    try await Core.RunningApplication.Testing.$mock.withValue(.init(
      runningApplicationsLookup: { requested in
        trace.yield(requested == .init("example.target") ? "lookup target" : "lookup unexpected")
        return []
      },
      onHide: { _ in trace.yield("hide unexpected"); return true },
      onUnhide: { _ in trace.yield("unhide unexpected"); return true },
      onActivate: { _, _ in trace.yield("activate unexpected"); return true }
    )) {
      let result = try await executor.execute(hideUnhideCommand(action), cgEventType: nil, snapshot: snapshot)
      #expect(result === snapshot)
    }
  }
  trace.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == ["hook", "lookup target"])
}

@Test(arguments: [true, false]) @MainActor
func executorHidePreviousUsesSnapshotWithoutLookup(hidden: Bool) async throws {
  let identifier = Core.BundleIdentifier("example.previous")
  let previous = Core.RunningApplication(.testing(identifier))
  let snapshot = UserSpace.Snapshot(apps: .init(previous: .init(bundleIdentifier: identifier, runningApplication: previous)))
  let (events, trace) = AsyncStream<String>.makeStream()
  let executor = Application.Executor(.testing, willExecute: { _ in trace.yield("hook") })

  try await Core.RunningApplication.Testing.$mock.withValue(.init(
    isHidden: hidden,
    runningApplicationsLookup: { _ in trace.yield("lookup unexpected"); return [] },
    onHide: { app in trace.yield(app === previous ? "hide previous" : "hide unexpected"); return true },
    onActivate: { _, _ in trace.yield("activate unexpected"); return true }
  )) {
    let command = try hideUnhideCommand("hide", identifier: Core.BundleIdentifier.WildCard.previous.rawValue)
    let result = try await executor.execute(command, cgEventType: nil, snapshot: snapshot)
    #expect(result === snapshot)
  }
  trace.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(recorded == (hidden ? ["hook"] : ["hook", "hide previous"]))
}
