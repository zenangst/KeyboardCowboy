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
    guard didLaunch else {
      didLaunch = true
      return
    }

    guard core?.contentStore.state == .initialized,
          AccessibilityPermission.shared.viewModel == .approved  else { return }

    let commandLineWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "CommandLineWindow" })

    if commandLineWindow?.isVisible == true { return }

    let mainWindow = NSApp.windows.mainWindow()

    if let mainWindow, mainWindow.isVisible {
      if let frameDescriptor = UserDefaults.standard.string(forKey: "MainWindowFrame") {
        mainWindow.setFrame(from: frameDescriptor)
      }
    } else {
      NotificationCenter.default.post(.init(name: Notification.Name("OpenMainWindow")))
      KeyboardCowboy.activate()
      if let frameDescriptor = UserDefaults.standard.string(forKey: "MainWindowFrame") {
        NSApp.windows.mainWindow()?.setFrame(from: frameDescriptor)
      }
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    saveFrame()
  }

  // MARK: NSWindowDelegate

  func windowDidResignKey(_ notification: Notification) {
    saveFrame()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    saveFrame()
    KeyboardCowboy.deactivate()
    return true
  }

  // MARK: Private methods

  @MainActor
  private func saveFrame() {
    guard let mainWindow = NSApp.windows.mainWindow() else { return }
    UserDefaults.standard.set(mainWindow.frameDescriptor, forKey: "MainWindowFrame")
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
