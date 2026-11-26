import ApplicationCatalog
import Commands
import CoreGraphics

public extension Workspaces {
  struct Workspace: Sendable {
    public let applications: [Application]
    public let tiling: Tiling?
    public let hideOtherApps: Bool

    public init(applications: [Application], tiling: Tiling? = nil, hideOtherApps: Bool = false) {
      self.applications = applications
      self.tiling = tiling
      self.hideOtherApps = hideOtherApps
    }

    /// Expands ordered snapshots without dispatching effects or updating workspace state.
    /// An empty Stage Manager plan leaves the warning to the caller.
    /// Pass `onlyUnhide: true` for previous-workspace activation; `nil` derives it from running apps.
    public func expand(
      catalog: [ApplicationCatalog.Application],
      runningApplications: [RunningApplication],
      windows: [Window] = [],
      frontmostBundleIdentifier: String? = nil,
      dynamicBundleIdentifiers: [String] = [],
      stageManagerEnabled: Bool = false,
      onlyUnhide: Bool? = nil,
    ) -> [Step] {
      let runningIDs = Set(runningApplications.compactMap(\.bundleIdentifier))
      let staticIDs = Set(applications.map(\.bundleIdentifier))
      let dynamic = dynamicBundleIdentifiers.filter { !staticIDs.contains($0) }
      let eligibleStatic = applications.filter { !$0.onlyWhenRunning || runningIDs.contains($0.bundleIdentifier) }
      let ids = stageManagerEnabled
        ? applications.map(\.bundleIdentifier) + dynamic
        : dynamic + eligibleStatic.map(\.bundleIdentifier)

      if ids.isEmpty {
        return stageManagerEnabled ? [] : [.hideAllApps(name: "Clean Workspace", delayMilliseconds: nil)]
      }

      let required = applications.lazy.filter { !$0.onlyWhenRunning }.map(\.bundleIdentifier)
      let rewriteToUnhide = eligibleStatic.count > 1 && (onlyUnhide ?? required.allSatisfy(runningIDs.contains))
      let windowPIDs = windows.filter {
        $0.id > 0 && $0.alpha == 1 && $0.size.width > 300 && $0.size.height > 200
          && !["borders", "WindowManager", "Window Server"].contains($0.ownerName)
      }
      .map(\.pid)

      let knownPIDs = Set(runningApplications.map(\.pid))
      let runningWindowCount = windowPIDs.count(where: knownPIDs.contains)
      let windowPIDSet = Set(windowPIDs)
      let wait: Set<Command.Application.Modifier> = [.waitForAppToLaunch]

      var steps: [Step] = ids.enumerated().compactMap { offset, id in
        guard let app = catalog.first(where: { $0.bundleIdentifier == id }) else { return nil }

        let isLast = offset == ids.count - 1
        let displayName = app.displayName
        let action: Command.Application.Action
        let name: String
        let modifiers: Set<Command.Application.Modifier>

        if stageManagerEnabled {
          guard isLast || !runningIDs.contains(id) else { return nil }

          (action, name, modifiers) = (.open, "", isLast ? wait : [.background])
        } else if isLast {
          (action, name, modifiers) = (.open, "Activate \(displayName)", wait)
        } else if id == frontmostBundleIdentifier {
          (action, name, modifiers) = (.unhide, "Unhide frontmost application \(displayName)", wait)
        } else if let running = runningApplications.first(where: { $0.bundleIdentifier == id }) {
          // Preserve the legacy ordered-window test, including its count of windows with running owners.
          let hasMatchingSlot = offset < runningWindowCount - 1 && windowPIDs[offset] == running.pid
          let unhide = running
            .isHidden ||
            (windowPIDSet.contains(running.pid) &&
              (hasMatchingSlot || running.isFinishedLaunching))
          (action, name, modifiers) = (unhide ? .unhide : .open, "\(unhide ? "Unhide" : "Open") \(displayName)",
                                       [.waitForAppToLaunch, .background])
        } else {
          (action, name, modifiers) = (.open, "Open \(displayName)", wait)
        }

        return .application(.init(
          application: app,
          name: name,
          action: rewriteToUnhide ? .unhide : action,
          modifiers: modifiers,
        ))
      }

      if !stageManagerEnabled, !runningIDs.contains("bobko.aerospace") {
        if let tiling { steps.append(.tiling(tiling)) }
        if hideOtherApps {
          steps.append(.hideAllApps(name: "Hide All Apps", delayMilliseconds: tiling == nil ? nil : 40))
        }
      }
      return steps
    }
  }
}
