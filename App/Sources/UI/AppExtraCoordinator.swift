import AppKit
import Bonzai

@MainActor
final class AppExtraCoordinator {
  private let core: Core
  private lazy var windowOpener = WindowOpener(core: core)

  init(core: Core) {
    self.core = core
  }

  func handle(_ action: AppMenuBarExtras.Action) {
    guard !launchArguments.isEnabled(.runningUnitTests) else { return }
    switch action {
    case .helpMenu(let action):
      handleHelpMenu(action)
    case .onAppear:
      if KeyboardCowboyApp.env() == .development {
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
}
