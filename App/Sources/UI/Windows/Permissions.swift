import AXEssibility
import AppKit
import Bonzai
import Foundation
import SwiftUI

@MainActor
final class Permissions: NSObject, NSWindowDelegate {
  private var window: NSWindow?
  private let settings = PermissionsSettings()

  func open() {
    let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable,
                                         .resizable, .fullSizeContentView]
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: styleMask) {
      PermissionsView(onAction: handle)
        .toolbar(content: {
          Text("Keyboard Cowboy: Permissions")
        })
        .frame(width: 640, height: 560)
    }
    let size = window.hostingController.sizeThatFits(in: .init(width: 320, height: 240))
    window.setFrame(NSRect(origin: .zero, size: size), display: false)

    window.delegate = self
    window.animationBehavior = .alertPanel
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.center()
    window.makeKeyAndOrderFront(nil)
    KeyboardCowboyApp.activate(setActivationPolicy: false)

    self.window = window
  }

  private func handle(_ action: PermissionsView.Action) {
    switch action {
    case .github:
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy")!)
    case .requestPermissions:
      window?.close()
      settings.show()
      AccessibilityPermission.shared.requestPermission()
    }
  }

  func windowWillClose(_ notification: Notification) {
    window = nil
  }
}
