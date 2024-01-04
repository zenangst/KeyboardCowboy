import SwiftUI

@MainActor
struct AppMenuBar: Scene {
  enum Action {
    case onAppear
    case openMainWindow
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
    }
  }
}

private struct _MenubarIcon: View {
  var body: some View {
    if launchArguments.isEnabled(.runningUnitTests) {
      Image(systemName: "testtube.2")
    } else if KeyboardCowboy.env() == .production {
      Image(systemName: "command")
    } else {
      Image(systemName: "hammer.circle")
    }
  }
}
