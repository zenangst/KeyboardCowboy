import AppKit
import Bonzai

@MainActor
final class AppExtraCoordinator {
  private let core: Core
  private let windowOpener: WindowOpener

  init(core: Core, windowOpener: WindowOpener) {
    self.core = core
    self.windowOpener = windowOpener
  }

  func handle(_ action: AppMenuBarExtras.Action) {
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }

    guard !isRunningPreview else { return }

    switch action {
    case .openKeyViewer:
      windowOpener.openKeyViewer()
    case .helpMenu(let action):
      handleHelpMenu(action)
    case .onAppear:
      if launchArguments.isEnabled(.openWindowAtLaunch) {
        windowOpener.openMainWindow()
      } else if !AXIsProcessTrustedWithOptions(nil) {
        windowOpener.openPermissions()
      } else if AppStorageContainer.shared.releaseNotes < KeyboardCowboyApp.marketingVersion {
        windowOpener.openReleaseNotes()
      }
    case .openEmptyConfigurationWindow:
      windowOpener.openEmptyConfig()
    case .openMainWindow:
      windowOpener.openMainWindow()
    case .install:
      moveToApplicationsFolderAndRestart()
    case .reveal:
      NSWorkspace.shared.selectFile(Bundle.main.bundlePath, inFileViewerRootedAtPath: "")
      NSWorkspace.shared.runningApplications
        .first(where: { $0.bundleIdentifier?.lowercased().contains("apple.finder") == true })?
        .activate()
    }
  }

  func handleHelpMenu(_ action: HelpMenu.Action) {
    switch action {
    case .releaseNotes:
      windowOpener.openReleaseNotes()
    case .wiki:
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki")!)
    case .discussions:
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/discussions")!)
    case .fileBug:
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/issues/new")!)
    }
  }

  private func moveToApplicationsFolderAndRestart() {
    let bundlePath = Bundle.main.bundlePath as NSString
    let applicationsPath = "/Applications" as NSString
    let destinationPath = applicationsPath.appendingPathComponent(bundlePath.lastPathComponent)

    guard bundlePath as String != destinationPath else { return }

    let fileManager = FileManager.default
    do {
      if fileManager.fileExists(atPath: destinationPath) {
        try fileManager.removeItem(atPath: destinationPath)
      }

      try fileManager.copyItem(atPath: bundlePath as String, toPath: destinationPath)

      let task = Process()
      task.launchPath = "/usr/bin/open"
      task.arguments = [destinationPath]

      task.launch()
      NSApp.terminate(nil)

    } catch {
      print("Failed to move app to /Applications: \(error)")
    }
  }
}
