import SwiftUI

struct AppMenuBar: Scene {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.scenePhase) private var scenePhase

  private var applicationName: String {
    switch KeyboardCowboy.env {
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

  var body: some Scene {
    MenuBarExtra(content: {
      Button("Open \(applicationName)", action: {
        openWindow(id: "MainWindow")
      })
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
    }
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .active:
        guard KeyboardCowboy.env == .production else { return }
        KeyboardCowboy.app.activate(ignoringOtherApps: true)
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
    MenubarIcon(color: .white, size: .init(width: 22, height: 22))
  }
}
