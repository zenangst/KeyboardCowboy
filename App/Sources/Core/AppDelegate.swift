import AXEssibility
import Cocoa
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  private var subscription: AnyCancellable?
  private var didLaunch: Bool = false
  var core: Core?

  // MARK: NSApplicationDelegate

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)

    // TODO: Fix this!
    subscription = NSApp.publisher(for: \.mainWindow)
      .sink { [weak self] _ in
        guard let self, let mainWindow = NSApp.windows.mainWindow() else { return }
        mainWindow.delegate = self
      }
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    guard core?.contentStore.state == .initialized,
          AccessibilityPermission.shared.viewModel == .approved  else { return }

    guard didLaunch else {
      didLaunch = true
      return
    }

    NotificationCenter.default.post(.init(name: Notification.Name("OpenMainWindow")))
    KeyboardCowboy.activate()
  }

  func applicationWillTerminate(_ notification: Notification) {
    guard let mainWindow = NSApp.windows.mainWindow() else { return }
    UserDefaults.standard.set(mainWindow.frameDescriptor, forKey: "MainWindowFrame")
  }

  // MARK: NSWindowDelegate

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if let mainWindow = NSApp.windows.mainWindow() {
      UserDefaults.standard.set(mainWindow.frameDescriptor, forKey: "MainWindowFrame")
    }
    KeyboardCowboy.deactivate()
    return true
  }
}

fileprivate extension Array<NSWindow> {
  @MainActor
  func mainWindow() -> NSWindow? {
    first(where: {
      $0.identifier?.rawValue.contains(KeyboardCowboy.mainWindowIdentifier) == true
    })
  }
}
