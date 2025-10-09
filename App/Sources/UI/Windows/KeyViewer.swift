import AppKit
import Bonzai
import KeyCodes
import MachPort
import SwiftUI

@MainActor
final class KeyViewer: NSObject, NSWindowDelegate {
  static let instance = KeyViewer()

  var isWindowOpen: Bool { window != nil }

  private lazy var publisher = KeyViewerPublisher()
  private var window: NSWindow?
  private var lastEventTime: Double = convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)

  override private init() {
    super.init()
  }

  func open() {
    if window != nil {
      window?.orderFrontRegardless()
      return
    }

    let window = createWindow()

    window.center()
    window.orderFrontRegardless()
    window.makeKeyAndOrderFront(nil)

    KeyboardCowboyApp.activate(setActivationPolicy: false)

    self.window = window
  }

  func windowWillClose(_: Notification) {
    window = nil
  }

  func handleInput(_ cgEvent: CGEvent, store: KeyCodesStore) {
    guard window != nil, cgEvent.type == .keyDown else { return }

    let keyCode = Int(cgEvent.getIntegerValueField(.keyboardEventKeycode))
    let modifiers = VirtualModifierKey.modifiers(for: keyCode, flags: cgEvent.flags, specialKeys: [])

    guard let displayValue = store.displayValue(for: keyCode, modifiers: modifiers) ?? store.displayValue(for: keyCode, modifiers: []) else {
      return
    }
    guard displayValue.lowercased() != "space" else {
      return
    }

    updateKeys(displayValue)
  }

  func handleInput(_ key: KeyShortcut) {
    guard window != nil else { return }

    updateKeys(key.key)
  }

  func handleString(_ string: String) {
    guard window != nil else { return }

    updateKeys(string.replacingOccurrences(of: " ", with: ""))
  }

  func handleFlagsChanged(_ cgFlags: CGEventFlags) {
    guard window != nil else { return }

    publisher.modifiers = cgFlags.modifierKeys
  }

  // MARK: Private methods

  private func createWindow() -> NSWindow {
    let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable, .fullSizeContentView]
    let view = KeyViewerView(publisher: publisher)
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: styleMask) {
      view
    }
    let minSize = CGSize(width: 128 * 2.08, height: 128)
    window.setFrame(NSRect(origin: .zero, size: minSize), display: false)

    window.animationBehavior = .none
    window.backgroundColor = .clear
    window.contentAspectRatio = CGSize(width: 520, height: 250)
    window.delegate = self
    window.minSize = minSize
    window.title = "Key Viewer"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.level = .statusBar
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true

    return window
  }

  private func updateKeys(_ displayValue: String) {
    let currentTimestamp = Self.convertTimestampToMilliseconds(DispatchTime.now().uptimeNanoseconds)
    let elapsedTime = currentTimestamp - lastEventTime

    if elapsedTime < 500 {
      if var lastKeystroke = publisher.keystrokes.last, lastKeystroke.key == displayValue {
        let count = publisher.keystrokes.count - 1
        lastKeystroke.iterations += 1
        publisher.keystrokes[count] = lastKeystroke
      } else if publisher.keystrokes.count > 6 {
        var newKeys = publisher.keystrokes
        newKeys.removeFirst()
        newKeys.append(.init(key: displayValue, iterations: 1))
        publisher.keystrokes = newKeys
      } else {
        publisher.keystrokes.append(.init(key: displayValue, iterations: 1))
      }
    } else {
      publisher.keystrokes = [.init(key: displayValue)]
    }

    lastEventTime = currentTimestamp
  }

  private static func convertTimestampToMilliseconds(_ timestamp: UInt64) -> Double {
    Double(timestamp) / 1_000_000 // Convert nanoseconds to milliseconds
  }
}
