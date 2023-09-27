import SwiftUI

struct AppMenuBar: Scene {
  enum Action {
    case onAppear
    case openMainWindow
    case reveal
  }

  @Environment(\.scenePhase) private var scenePhase
  @StateObject var appUpdater = AppUpdater()

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
      Button {
        onAction(.openMainWindow)
      } label: {
        Image(systemName: "text.and.command.macwindow")
        Text("Open \(applicationName)")
      }

      Button {
        appUpdater.checkForUpdates()
      } label: {
        Image(systemName: "sparkles")
        Text("Check for updates…")
      }

      Divider()

      Button(action: {
        NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki")!)
      }, label: {
        Image(systemName: "info.square")
        Text("Wiki")
      })

      Button(action: {
        NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/discussions")!)
      }, label: {
        Image(systemName: "bubble.left")
        Text("Discussions")
      })

      Button(action: {
        NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/issues/new")!)
      }, label: {
        Image(systemName: "ladybug")
        Text("File a Bug")
      })

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
    if launchArguments.isEnabled(.runningUnitTests) {
      Image(systemName: "testtube.2")
    } else if KeyboardCowboy.env == .production {
      Image(systemName: "command")
    } else {
      Image(systemName: "hammer.circle")
    }
  }
}
