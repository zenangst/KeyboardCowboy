import Cocoa
import Windows

final class SystemHideAllAppsRunner {
  static func run(workflowCommands: [Command]) async {
    guard let screen = NSScreen.main else { return }

    let exceptBundleIdentifiers = workflowCommands.compactMap {
      if case .application(let command) = $0, command.action == .open { return command.application.bundleIdentifier }
      return nil
    }

    let windows = Set(indexWindowsInStage(getWindows(), targetRect: screen.visibleFrame)
      .map(\.ownerName))

    let apps = NSWorkspace.shared.runningApplications
      .filter {
        guard let localizedName = $0.localizedName else { return false }

        guard windows.contains(localizedName) else { return false }

        guard !exceptBundleIdentifiers.contains($0.bundleIdentifier ?? "") else { return false }
        guard let bundleURL = $0.bundleURL else { return false }

        let pathExtension = (bundleURL.lastPathComponent as NSString).pathExtension
        let path = bundleURL.path()

        guard pathExtension == "app" else { return false }
        guard !path.contains("Frameworks/") else { return false }

        return true
      }
      .filter { $0.activationPolicy == .regular && $0.isHidden == false }


    for app in apps {
      app.hide()
      try? await Task.sleep(for: .milliseconds(25))
    }
  }

  // MARK: Private methods

  private static func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private static func indexWindowsInStage(_ models: [WindowModel], targetRect: CGRect) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 150, height: 150)
    let windows: [WindowModel] = models
      .filter {
        $0.id > 0 &&
        $0.ownerName != "borders" &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName) &&
        $0.rect.intersects(targetRect)
      }

    return windows
  }
}
