import SwiftUI

@MainActor
struct AppMenuBarExtras: Scene {
  enum Action {
    case onAppear
    case openMainWindow
    case openEmptyConfigurationWindow
    case reveal
    case install
    case openKeyViewer
    case helpMenu(HelpMenu.Action)
  }

  private var applicationName: String {
    switch KeyboardCowboyApp.env() {
    case .previews:    "Keyboard Cowboy (designTime)"
    case .production:  "Keyboard Cowboy"
    case .development: "Keyboard Cowboy (dev)"
    }
  }

  @AppStorage("showMenuBarIcon") private var showMenuBarExtras: Bool = true
  @EnvironmentObject private var openWindow: WindowOpener
  @ObservedObject private var keyboardCleaner: KeyboardCleaner

  private let machPortCoordinator: MachPortCoordinator
  private let core: Core
  private let contentStore: ContentStore
  private let onAction: (Action) -> Void

  init(core: Core, contentStore: ContentStore, keyboardCleaner: KeyboardCleaner, onAction: @escaping (Action) -> Void) {
    self.core = core
    self.contentStore = contentStore
    self.machPortCoordinator = core.machPortCoordinator
    self.onAction = onAction
    _keyboardCleaner = .init(initialValue: keyboardCleaner)
  }

  var body: some Scene {
    MenuBarExtra(isInserted: $showMenuBarExtras, content: {
      Button { onAction(.openMainWindow) } label: { Text("Open \(applicationName)") }
      AppMenu(modePublisher: KeyboardCowboyModePublisher(source: core.machPortCoordinator.$mode)) { newValue in
        if newValue {
          core.machPortCoordinator.startIntercept()
        } else {
          core.machPortCoordinator.disable()
        }
      }
      Divider()

      Button { onAction(.openKeyViewer) } label: { Text("Key Viewer") }
      Toggle(isOn: $keyboardCleaner.isEnabled, label: { Text("Keyboard Cleaner") })
        .toggleStyle(.checkbox)

      Divider()
      HelpMenu { onAction(.helpMenu($0)) }
      Divider()
      Text("Version: \(KeyboardCowboyApp.marketingVersion) (\(KeyboardCowboyApp.buildNumber))")
#if DEBUG
      Button(action: { onAction(.reveal) }, label: {
        Text("Reveal")
      })
      if !Bundle.main.bundlePath.hasPrefix("/Applications") {
        Button(action: { onAction(.install) }, label: { Text("Move to Applications Folder") })
      }
#endif
      Button(action: {
        NSApplication.shared.terminate(nil)
      }, label: {
        Text("Quit")
      })
      .keyboardShortcut("q", modifiers: [.command])
    }) {
      _MenubarIcon()
        .onAppear(perform: { onAction(.onAppear) })
        .onChange(of: contentStore.state) { newValue in
          if newValue == .noConfiguration {
            onAction(.openEmptyConfigurationWindow)
          }
        }
    }
  }

  private struct _MenubarIcon: View {
    var body: some View {
      if isRunningPreview {
        Image(systemName: "theatermask.and.paintbrush")
      } else if launchArguments.isEnabled(.runningUnitTests) {
        Image(systemName: "testtube.2")
      } else if KeyboardCowboyApp.env() == .production {
        Image(systemName: "command")
      } else {
        Image(systemName: "hammer.circle")
      }
    }
  }
}
