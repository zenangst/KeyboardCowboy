import SwiftUI

struct FocusableProxy: NSViewRepresentable {
  typealias NSViewType = FocusableNSView

  private let id: CustomStringConvertible
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(id: CustomStringConvertible, onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.id = id
    self.onKeyDown = onKeyDown
  }

  func makeNSView(context: Context) -> FocusableNSView { FocusableNSView(id: id, onKeyDown: onKeyDown) }
  func updateNSView(_ nsView: FocusableNSView, context: Context) { }
}

class FocusableNSView: NSView {
  static func becomeFirstResponderNotification(_ id: CustomStringConvertible) -> Notification.Name {
    Notification.Name("FocusableNSView[\(id)].becomeFirstResponder")
  }

  override var canBecomeKeyView: Bool { true }
  override var acceptsFirstResponder: Bool { true }
  private let id: CustomStringConvertible
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(id: CustomStringConvertible, onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.id = id
    self.onKeyDown = onKeyDown
    super.init(frame: .zero)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(becomeFirstResponder),
                                           name: Self.becomeFirstResponderNotification(id), object: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)
    onKeyDown(Int(event.keyCode), event.modifierFlags)
  }
}
