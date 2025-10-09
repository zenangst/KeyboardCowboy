import AppKit
import Bonzai
import KeyCodes
import MachPort
import SwiftUI

@MainActor
final class UserPromptWindow: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  func open(_ content: () -> some View) {
    if window != nil {
      window?.orderFrontRegardless()
      return
    }

    let window = createWindow(content)

    window.center()
    window.orderFrontRegardless()
    window.makeKeyAndOrderFront(nil)

    KeyboardCowboyApp.activate(setActivationPolicy: false)

    self.window = window
  }

  func windowWillClose(_: Notification) {
    window = nil
  }

  // MARK: Private methods

  private func createWindow(_ content: () -> some View) -> NSWindow {
    let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable, .fullSizeContentView]
    let windowEnv = WindowEnvironment()
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: styleMask) {
      content()
        .padding([.bottom, .leading, .trailing], 8)
        .padding(.top, 32)
        .frame(minWidth: 200, minHeight: 80, maxHeight: .infinity)
        .background(
          ZStack {
            ZenVisualEffectView(material: .hudWindow)
              .mask {
                LinearGradient(
                  stops: [
                    .init(color: .black, location: 0),
                    .init(color: .clear, location: 1),
                  ],
                  startPoint: .top,
                  endPoint: .bottom,
                )
              }
            ZenVisualEffectView(material: .contentBackground)
              .mask {
                LinearGradient(
                  stops: [
                    .init(color: .black.opacity(0.5), location: 0),
                    .init(color: .black, location: 0.75),
                  ],
                  startPoint: .top,
                  endPoint: .bottom,
                )
              }
          },
        )
        .ignoresSafeArea(.all)
        .environmentObject(windowEnv)
    }
    window.setFrame(NSRect(origin: .zero, size: .zero), display: false)

    window.animationBehavior = .documentWindow
    window.backgroundColor = .clear
    window.isMovableByWindowBackground = true
    window.delegate = self
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.level = .statusBar
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true

    windowEnv.window = window

    return window
  }
}

final class WindowEnvironment: ObservableObject {
  weak var window: NSWindow?
}
