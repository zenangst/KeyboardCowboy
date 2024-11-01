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
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: [.titled, .closable]) {
      PermissionsView(onAction: handle)
        .toolbar(content: {
          Spacer()
          Text("Keyboard Cowboy: Permissions")
          Spacer()
        })
        .frame(width: 640, height: 560)
    }
    self.window = window
    window.center()
    window.orderFrontRegardless()
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
