import AppKit
import ApplicationTriggers
import Combine
import Testing

@MainActor
private final class AppEvents {
  var snapshot = ApplicationTriggers.Snapshot(runningBundleIdentifiers: [], frontmostBundleIdentifier: nil)
  var handlers: [@MainActor (ApplicationTriggers.Change) -> Void] = []
  var snapshotReads = 0
  var cancellations = 0
  var enabledModes: Set<String> = []

  var source: ApplicationTriggers.Source {
    .init(snapshot: {
      self.snapshotReads += 1
      return self.snapshot
    }, observe: { [self] handler in
      self.handlers.append(handler)
      return AnyCancellable { [weak self] in self?.cancellations += 1 }
    })
  }
}

private let app = "com.example.app"
private let rule = ApplicationTriggers.Rule(workflowID: "workflow", bundleIdentifier: app,
                                            contexts: Set(ApplicationTriggers.Context.allCases))

@Test @MainActor func subscribesOnlyWhenAnEnabledContextExistsAndSeedsWithoutMatching() {
  let events = AppEvents()
  events.snapshot = .init(runningBundleIdentifiers: [app], frontmostBundleIdentifier: app)
  var matches: [ApplicationTriggers.Match] = []
  let installation = ApplicationTriggers.install(rules: [], source: events.source) { matches += $0 }
  installation.update(rules: [
    .init(workflowID: "disabled-group", bundleIdentifier: app, contexts: [.launched], isGroupEnabled: false),
    .init(workflowID: "disabled-workflow", bundleIdentifier: app, contexts: [.launched], isWorkflowEnabled: false),
    .init(workflowID: "no-context", bundleIdentifier: app, contexts: []),
  ])
  #expect(events.handlers.isEmpty)
  #expect(events.snapshotReads == 0)

  installation.update(rules: [rule])
  #expect(events.handlers.count == 1)
  #expect(events.snapshotReads == 1)
  events.handlers.last?(.runningApplications([app]))
  events.handlers.last?(.frontmostApplication(app))
  #expect(matches.isEmpty)
  events.handlers.last?(.frontmostApplication(nil))
  events.handlers.last?(.runningApplications([]))
  #expect(matches.map(\.context) == [.resignFrontMost, .closed])
}

@Test @MainActor func updatesRulesAndReadsModesWithoutResubscribing() {
  let events = AppEvents()
  var workflowIDs: [String] = []
  let gatedRule = ApplicationTriggers.Rule(workflowID: "gated", bundleIdentifier: app,
                                           contexts: [.launched], requiredModeIDs: ["mode"])
  let installation = ApplicationTriggers.install(rules: [gatedRule], source: events.source,
                                                 enabledModeIDs: { events.enabledModes }) { workflowIDs += $0.map(\.workflowID) }
  events.handlers.last?(.runningApplications([app]))
  #expect(workflowIDs.isEmpty)
  events.enabledModes = ["mode"]
  events.handlers.last?(.runningApplications([app]))
  #expect(workflowIDs.isEmpty)
  events.handlers.last?(.runningApplications([]))
  events.handlers.last?(.runningApplications([app]))
  installation.update(rules: [rule])
  events.handlers.last?(.runningApplications([]))
  #expect(workflowIDs == ["gated", "workflow"])
  #expect(events.handlers.count == 1)
  #expect(events.snapshotReads == 1)
  #expect(events.cancellations == 0)
}

@Test @MainActor func removalStopsAndReinstallationIgnoresStaleEvents() {
  let events = AppEvents()
  var matches: [ApplicationTriggers.Match] = []
  let installation = ApplicationTriggers.install(rules: [rule], source: events.source) { matches += $0 }
  installation.update(rules: [])
  installation.stop()
  #expect(events.cancellations == 1)
  events.handlers.first?(.runningApplications([app]))
  #expect(matches.isEmpty)

  events.snapshot.runningBundleIdentifiers = [app]
  installation.update(rules: [rule])
  #expect(events.snapshotReads == 2)
  #expect(events.handlers.count == 2)
  events.handlers.first?(.runningApplications([]))
  events.handlers.last?(.runningApplications([app]))
  #expect(matches.isEmpty)
  events.handlers.last?(.runningApplications([]))
  #expect(matches.map(\.context) == [.closed])
}

@Test @MainActor func droppingInstallationCancelsObservation() {
  let events = AppEvents()
  var installation: ApplicationTriggers.Installation? =
    ApplicationTriggers.install(rules: [rule], source: events.source) { _ in Issue.record("Unexpected match") }
  #expect(installation != nil)
  installation = nil
  #expect(events.cancellations == 1)
  events.handlers.last?(.runningApplications([app]))
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_APPLICATION_TRIGGER_FIXTURE"] != nil))
@MainActor func liveInstallationObservesDisposableApplication() async throws {
  let fixture = URL(filePath: try #require(ProcessInfo.processInfo.environment["KC_APPLICATION_TRIGGER_FIXTURE"]))
  let bundleID = try #require(Bundle(url: fixture)?.bundleIdentifier)
  try #require(NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty)
  let screen = try #require(NSScreen.screens.first)
  let displayID = try #require(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
  let result = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: result) }
  var contexts: [ApplicationTriggers.Context] = []
  let fixtureRule = ApplicationTriggers.Rule(workflowID: "fixture", bundleIdentifier: bundleID,
                                             contexts: Set(ApplicationTriggers.Context.allCases))
  let installation = ApplicationTriggers.install(rules: [fixtureRule]) { contexts += $0.map(\.context) }
  defer { installation.stop() }
  #expect(contexts.isEmpty)

  func waitFor(_ expected: Set<ApplicationTriggers.Context>) async throws {
    let deadline = ContinuousClock.now + .seconds(5)
    while !expected.isSubset(of: contexts), ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(expected.isSubset(of: contexts))
  }

  let configuration = NSWorkspace.OpenConfiguration()
  configuration.createsNewApplicationInstance = true
  configuration.arguments = ["resizable", result.path, displayID.stringValue]
  let application = try await NSWorkspace.shared.openApplication(at: fixture, configuration: configuration)
  defer { if !application.isTerminated { application.terminate() } }
  try await waitFor([.launched, .frontMost])
  try #require(application.terminate())
  try await waitFor([.closed, .resignFrontMost])
  #expect(contexts.count == 4)
}
