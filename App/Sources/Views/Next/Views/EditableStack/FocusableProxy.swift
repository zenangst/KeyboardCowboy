import SwiftUI

struct FocusableProxy: NSViewRepresentable {
  typealias NSViewType = FocusableNSView

  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.onKeyDown = onKeyDown
  }

  func makeNSView(context: Context) -> FocusableNSView { FocusableNSView(onKeyDown: onKeyDown) }
  func updateNSView(_ nsView: FocusableNSView, context: Context) { }
}

class FocusableNSView: NSView {
  override var canBecomeKeyView: Bool { true }
  override var acceptsFirstResponder: Bool { true }
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.onKeyDown = onKeyDown
    super.init(frame: .zero)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)
    onKeyDown(Int(event.keyCode), event.modifierFlags)
  }
}
