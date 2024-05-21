import SwiftUI

@MainActor
struct AppMenuBarExtras: Scene {
  enum Action {
    case onAppear
    case openMainWindow
    case openEmptyConfigurationWindow
    case reveal
  }

  private var applicationName: String {
    switch KeyboardCowboy.env() {
    case .previews:
      return "Keyboard Cowboy (designTime)"
    case .production:
      return "Keyboard Cowboy"
    case .development:
      return "Keyboard Cowboy (dev)"
    }
  }

  private let contentStore: ContentStore
  private let onAction: (Action) -> Void
  private let pub = NotificationCenter.default
    .publisher(for: NSNotification.Name("OpenMainWindow"))

  init(contentStore: ContentStore, onAction: @escaping (Action) -> Void) {
    self.contentStore = contentStore
    self.onAction = onAction
  }

  var body: some Scene {
    MenuBarExtra(content: {
      Button { onAction(.openMainWindow) } label: { Text("Open \(applicationName)") }
      AppMenu()
      Divider()
      HelpMenu()
      Divider()
      Text("Version: \(KeyboardCowboy.marektingVersion) (\(KeyboardCowboy.buildNumber))")
#if DEBUG
      Button(action: { onAction(.reveal) }, label: {
        Text("Reveal")
      })
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
        .onReceive(pub, perform: { output in
          onAction(.openMainWindow)
          UserSpace.Application.current.ref.activate(options: .activateAllWindows)
        })
        .onChange(of: contentStore.state) { newValue in
          if newValue == .noConfiguration {
            onAction(.openEmptyConfigurationWindow)
          }
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
    } else if KeyboardCowboy.env() == .production {
      Image(systemName: "command")
    } else {
      Image(systemName: "hammer.circle")
    }
  }
}
