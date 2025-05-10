import Apps
import AXEssibility
import Carbon
import Cocoa
import MachPort
import Windows

final class SystemHideAllAppsRunner {
  @MainActor static var machPort: MachPortEventController?

  static func run(targetApplication: Application? = nil, checkCancellation: Bool, workflowCommands: [Command]) async throws {
    guard let currentScreen = NSScreen.main else { return }

    var targetScreenFrame: CGRect = currentScreen.visibleFrame
    var excludedBundleIdentifiers = workflowCommands.compactMap {
      if case .application(let command) = $0, (command.action == .open || command.action == .unhide) { return command.application.bundleIdentifier }
      return nil
    }

    excludedBundleIdentifiers.append(Bundle.main.bundleIdentifier!)

    var (processIdentifiers, apps) = Self.runningApplications(in: targetScreenFrame, targetApplication: targetApplication,
                                                              targetPid: nil, options: [.excludeDesktopElements, .optionOnScreenOnly],
                                                              exceptBundleIdentifiers: excludedBundleIdentifiers)

    if let targetApplication, NSScreen.screens.count > 1 {
      // Find target application
      if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == targetApplication.bundleIdentifier }) {
        if !processIdentifiers.contains(Int(app.processIdentifier)) {
          for screen in NSScreen.screens where screen != currentScreen {
            let windows = indexWindowsInStage(getWindows(options: [.excludeDesktopElements]), targetRect: screen.visibleFrame)
            let pids = Set(windows.map(\.ownerPid.rawValue))

            if pids.contains(Int(app.processIdentifier)) {
              targetScreenFrame = screen.visibleFrame
              (processIdentifiers, apps) = Self.runningApplications(in: targetScreenFrame, targetApplication: targetApplication,
                                                                    targetPid: Int(app.processIdentifier),
                                                                    options: [.excludeDesktopElements],
                                                                    exceptBundleIdentifiers: excludedBundleIdentifiers)
              break
            }
          }
        }
      }
    }


    var validPids = Set<Int>()
    if let targetApplication {
      if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == targetApplication.bundleIdentifier }) {
        validPids.insert(Int(app.processIdentifier))
      }
    }

    for exceptBundleIdentifier in excludedBundleIdentifiers {
      if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == exceptBundleIdentifier }) {
        validPids.insert(Int(app.processIdentifier))
      }
    }

    guard !apps.isEmpty else {
      return
    }

    // Fix Podcasts app not hiding when calling `NSRunningApplication.hide()`
    let misbehavingBundles = Set(arrayLiteral: "com.apple.podcasts")
    for app in apps where misbehavingBundles.contains(app.bundleIdentifier ?? "") {
      if #available(macOS 14.0, *) {
        app.activate(from: NSWorkspace.shared.frontmostApplication!, options: .activateAllWindows)
      } else {
        app.activate(options: .activateAllWindows)
      }

      try await Task.sleep(for: .milliseconds(25))
      _ = try await machPort?.post(kVK_ANSI_H, type: .keyDown, flags: .maskCommand)
      _ = try await machPort?.post(kVK_ANSI_H, type: .keyUp, flags: .maskCommand)
      apps.removeAll(where: { $0.bundleIdentifier == app.bundleIdentifier })
    }

    for app in apps {
      app.hide()
      processIdentifiers.insert(Int(app.processIdentifier))
    }

    var timeout: Int = 0
    let limit: Int = 100
    var waitingForWindowsToDisappear: Bool = true

    while waitingForWindowsToDisappear {
      if checkCancellation {
        try Task.checkCancellation()
      }

      let windows = indexWindowsInStage(getWindows(options: [.optionOnScreenOnly, .excludeDesktopElements]), targetRect: targetScreenFrame)
      let windowsProcessIds = Set(windows.map(\.ownerPid.rawValue))

      if windowsProcessIds == validPids {
        waitingForWindowsToDisappear = false
      } else if timeout >= limit {
        waitingForWindowsToDisappear = false
      } else {
        timeout += 1
        try await Task.sleep(for: .milliseconds(10))
      }
    }
  }

  private static func runningApplications(in targetRect: CGRect, targetApplication: Application? = nil,
                                          targetPid: Int?, options: CGWindowListOption,
                                          exceptBundleIdentifiers: [String]) -> (Set<Int>, [NSRunningApplication]) {
    let processIdentifiers = Set(indexWindowsInStage(getWindows(options: options), targetRect: targetRect)
      .map(\.ownerPid.rawValue))
      .filter({ $0 != targetPid })

    let applications = NSWorkspace.shared.runningApplications
      .filter {
        guard $0.bundleIdentifier != targetApplication?.bundleIdentifier else { return false }

        let processIdentifier = Int($0.processIdentifier)
        guard processIdentifiers.contains(processIdentifier) else { return false }

        guard !exceptBundleIdentifiers.contains($0.bundleIdentifier ?? "") else { return false }
        guard let bundleURL = $0.bundleURL else { return false }

        let pathExtension = (bundleURL.lastPathComponent as NSString).pathExtension
        let path = bundleURL.path()

        guard pathExtension == "app" else { return false }
        guard !path.contains("Frameworks/") else { return false }

        return true
      }
      .filter { $0.activationPolicy == .regular && $0.isHidden == false }

    return (processIdentifiers, applications)
  }

  // MARK: Private methods

  private static func getWindows(options: CGWindowListOption) -> [WindowModel] {
    ((try? WindowsInfo.getWindows(options)) ?? [])
  }

  private static func indexWindowsInStage(_ models: [WindowModel], targetRect: CGRect) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 200)
    let windows: [WindowModel] = models
      .filter {
        $0.id > 0 &&
        $0.ownerName != "borders" &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName) &&
        $0.rect.intersects(targetRect)
      }

    return windows
  }
}
