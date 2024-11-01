import ApplicationServices
import AXEssibility
import Bonzai
import Combine
import Cocoa
import SwiftUI
import LaunchArguments
import InputSources
@_exported import Inject

@main
struct KeyboardCowboyApp: App {
#if DEBUG
  static func env() -> AppEnvironment {
    guard !isRunningPreview else { return .previews }

    if let override = ProcessInfo.processInfo.environment["APP_ENVIRONMENT_OVERRIDE"],
       let env = AppEnvironment(rawValue: override) {
      return env
    } else {
      return .production
    }
  }
#else
  static func env() -> AppEnvironment { .production }
#endif

  @FocusState var focus: AppFocus?
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private let coordinator: AppExtraCoordinator
  private var open: Bool = true
  private let core: Core
  @ObservedObject private var contentStore: ContentStore

  init() {
    let core = Core()
    contentStore = core.contentStore
    self.core = core
    self.coordinator = AppExtraCoordinator(core: core)

    Task { @MainActor in
      InjectConfiguration.animation = .spring()
      Benchmark.shared.isEnabled = launchArguments.isEnabled(.benchmark)
    }

    if launchArguments.isEnabled(.injection) { _ = InjectConfiguration.load }
  }

  var body: some Scene {
    AppMenuBarExtras(contentStore: core.contentStore, keyboardCleaner: core.keyboardCleaner,
                     onAction: { action in coordinator.handle(action) })

    Settings { SettingsView().environmentObject(OpenPanelController()) }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
  }
}
