import SwiftUI

struct AppMenuBar: Scene {
  enum Action {
    case openMainWindow
    case reveal
  }

  @Environment(\.scenePhase) private var scenePhase

  private var applicationName: String {
    switch KeyboardCowboy.env {
    case .designTime:
      return "Keyboard Cowboy (designTime)"
    case .production:
      return "Keyboard Cowboy"
    case .development:
      return "Keyboard Cowboy (dev)"
    }
  }

  enum ApplicationState {
    case active, inactive

    var iconName: String {
      switch self {
      case .active: return "Menubar_active"
      case .inactive: return "Menubar_inactive"
      }
    }
  }

  private let onAction: (Action) -> Void
  private let pub = NotificationCenter.default
    .publisher(for: NSNotification.Name("OpenMainWindow"))

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some Scene {
    MenuBarExtra(content: {
      Button("Open \(applicationName)") { onAction(.openMainWindow) }
      Button("Reveal") { onAction(.reveal) }
      Divider()
      Button("Check for updates...", action: {})
      Button("Provide feedback...", action: {
        NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/issues/new")!)
      })
      Divider()
      Button("Quit") { NSApplication.shared.terminate(nil) }
        .keyboardShortcut("q", modifiers: [.command])
    }) {
      _MenubarIcon()
        .onAppear {
          if KeyboardCowboy.env == .development {
            onAction(.openMainWindow)
          }
        }
        .onReceive(pub, perform: { output in
          onAction(.openMainWindow)
        })
    }
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .active:
        guard KeyboardCowboy.env == .production else { return }
        KeyboardCowboy.activate()
      case .inactive, .background:
        break
      default:
        break
      }
    }
  }
}

private struct _MenubarIcon: View {
  var body: some View {
    if KeyboardCowboy.env == .production {
      Text("⌘")
    } else {
      Image(systemName: "hammer.circle")
    }
  }
}
