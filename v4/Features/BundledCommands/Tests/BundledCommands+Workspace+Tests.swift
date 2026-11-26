import ApplicationCatalog
import BundledCommandsFeature
import Commands
import CoreGraphics
import Testing

private typealias Workspace = BundledCommands.Workspace
private let wait: Set<Command.Application.Modifier> = [.waitForAppToLaunch]
private let backgroundWait: Set<Command.Application.Modifier> = [.waitForAppToLaunch, .background]

private func catalog(_ ids: String...) -> [ApplicationCatalog.Application] {
  ids.map { .init(bundleIdentifier: $0, bundleName: $0, path: "/Applications/\($0).app") }
}

private func running(_ id: String?, _ pid: Int32, hidden: Bool = false, finished: Bool = false) -> Workspace.RunningApplication {
  .init(pid: pid, bundleIdentifier: id, isHidden: hidden, isFinishedLaunching: finished)
}

private func window(_ pid: Int32, id: Int = 1, owner: String = "Fixture",
                    width: CGFloat = 420, height: CGFloat = 250, alpha: Double = 1) -> Workspace.Window {
  .init(id: id, pid: pid, ownerName: owner, size: CGSize(width: width, height: height), alpha: alpha)
}

private struct App: Equatable {
  let id: String
  let action: Command.Application.Action
  let name: String
  let modifiers: Set<Command.Application.Modifier>

  init(_ id: String, _ action: Command.Application.Action, _ name: String,
       _ modifiers: Set<Command.Application.Modifier>) {
    self.id = id
    self.action = action
    self.name = name
    self.modifiers = modifiers
  }
}

private func apps(_ steps: [Workspace.Step]) -> [App] {
  steps.compactMap {
    guard case .application(let step) = $0 else { return nil }
    return App(step.application.bundleIdentifier, step.action, step.name, step.modifiers)
  }
}

@Test func nonStageExpansionPreservesOrderOptionsAndFinalApp() {
  let workspace = Workspace(applications: [.init("Skip", onlyWhenRunning: true), .init("Front"), .init("Final")],
                            tiling: .arrangeLeftRight, hideOtherApps: true)
  let steps = workspace.expand(catalog: catalog("Final", "Dynamic", "Skip", "Front"),
                               runningApplications: [running("Front", 1)], frontmostBundleIdentifier: "Front",
                               dynamicBundleIdentifiers: ["Front", "Dynamic", "Dynamic", "Skip"])
  #expect(apps(steps) == [
    App("Dynamic", .open, "Open Dynamic", wait),
    App("Dynamic", .open, "Open Dynamic", wait),
    App("Front", .unhide, "Unhide frontmost application Front", wait),
    App("Final", .open, "Activate Final", wait),
  ])
  #expect(Array(steps.suffix(2)) == [
    .tiling(.arrangeLeftRight),
    .hideAllApps(name: "Hide All Apps", delayMilliseconds: 40),
  ])
}

@Test func runningAppSelectionUsesEligibleOrderedWindowsAndHiddenState() {
  let workspace = Workspace(applications: [.init("Ordered"), .init("Hidden"), .init("Finished"),
                                           .init("Filtered"), .init("Final")])
  let steps = workspace.expand(
    catalog: catalog("Ordered", "Hidden", "Finished", "Filtered", "Final"),
    runningApplications: [running("Ordered", 1), running("Hidden", 2, hidden: true),
                          running("Finished", 3, finished: true), running("Filtered", 4, finished: true)],
    windows: [window(4, id: 0), window(1), window(3), window(4, owner: "borders"),
              window(4, owner: "WindowManager"), window(4, owner: "Window Server"),
              window(4, width: 300), window(4, height: 200), window(4, alpha: 0.5)],
  )
  #expect(apps(steps) == [
    App("Ordered", .unhide, "Unhide Ordered", backgroundWait),
    App("Hidden", .unhide, "Unhide Hidden", backgroundWait),
    App("Finished", .unhide, "Unhide Finished", backgroundWait),
    App("Filtered", .open, "Open Filtered", backgroundWait),
    App("Final", .open, "Activate Final", wait),
  ])
}

@Test func missingFinalCatalogEntryDoesNotPromoteTheEarlierApp() {
  let workspace = Workspace(applications: [.init("Running"), .init("Missing")])
  let steps = workspace.expand(catalog: catalog("Running"), runningApplications: [running("Running", 1)],
                               windows: [window(1), window(99, id: 2)])
  #expect(apps(steps) == [App("Running", .open, "Open Running", backgroundWait)])
}

@Test func stageManagerKeepsStaticFirstAndIgnoresNonStageEffects() {
  let workspace = Workspace(applications: [.init("SkipRunning"), .init("Optional", onlyWhenRunning: true)],
                            tiling: .fill, hideOtherApps: true)
  let steps = workspace.expand(catalog: catalog("SkipRunning", "Optional", "Dynamic"),
                               runningApplications: [running("SkipRunning", 1), running("Dynamic", 2)],
                               dynamicBundleIdentifiers: ["Optional", "Dynamic"], stageManagerEnabled: true)
  #expect(apps(steps) == [
    App("Optional", .open, "", [.background]),
    App("Dynamic", .open, "", wait),
  ])
  #expect(steps.count == 2)
  #expect(workspace.expand(catalog: [], runningApplications: [], stageManagerEnabled: true).isEmpty)
}

@Test func unhideRewriteUsesEligibleStaticCountAndKeepsTheOriginalName() {
  let workspace = Workspace(applications: [.init("One"), .init("Two", onlyWhenRunning: true)])
  let catalog = catalog("One", "Two", "Dynamic")
  let runningApps = [running("One", 1), running("Two", 2)]
  #expect(apps(workspace.expand(catalog: catalog, runningApplications: runningApps)) == [
    App("One", .unhide, "Open One", backgroundWait),
    App("Two", .unhide, "Activate Two", wait),
  ])
  #expect(apps(workspace.expand(catalog: catalog, runningApplications: runningApps, onlyUnhide: false)).map(\.action)
    == [.open, .open])
  #expect(apps(workspace.expand(catalog: catalog, runningApplications: [], dynamicBundleIdentifiers: ["Dynamic"],
                                onlyUnhide: true)).map(\.action) == [.open, .open])
  #expect(apps(Workspace(applications: []).expand(catalog: catalog, runningApplications: [],
                                                 dynamicBundleIdentifiers: ["Dynamic"], onlyUnhide: true)).map(\.action)
    == [.open])
}

@Test func emptyCleanupPrecedesAeroSpaceSuppression() {
  let empty = Workspace(applications: [.init("Optional", onlyWhenRunning: true)], tiling: .fill, hideOtherApps: true)
  let aeroSpace = [running("bobko.aerospace", 1)]
  #expect(empty.expand(catalog: [], runningApplications: aeroSpace)
    == [.hideAllApps(name: "Clean Workspace", delayMilliseconds: nil)])
  #expect(Workspace(applications: []).expand(catalog: [], runningApplications: [], stageManagerEnabled: true).isEmpty)
  let workspace = Workspace(applications: [.init("One")], tiling: .fill, hideOtherApps: true)
  let steps = workspace.expand(catalog: catalog("One"), runningApplications: aeroSpace)
  #expect(apps(steps) == [App("One", .open, "Activate One", wait)])
  #expect(steps.count == 1)
  #expect(Workspace(applications: [.init("Unknown")], hideOtherApps: true).expand(catalog: [], runningApplications: [])
    == [.hideAllApps(name: "Hide All Apps", delayMilliseconds: nil)])
}

@Test(arguments: Workspace.Tiling.allCases)
func keepsEachWorkspaceTilingAfterTheApplication(_ tiling: BundledCommands.Workspace.Tiling) {
  let workspace = Workspace(applications: [.init("One")], tiling: tiling, hideOtherApps: true)
  let steps = workspace.expand(catalog: catalog("One"), runningApplications: [])
  #expect(steps.count == 3)
  #expect(Array(steps.dropFirst()) == [.tiling(tiling), .hideAllApps(name: "Hide All Apps", delayMilliseconds: 40)])
}
