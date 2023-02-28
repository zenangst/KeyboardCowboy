import SwiftUI
import Combine

struct FocusableProxy<Identifier>: NSViewRepresentable where Identifier: Equatable,
                                                             Identifier: Hashable,
                                                             Identifier: CustomStringConvertible {
  static func post(_ id: Identifier?) {
    if let id {
      NotificationCenter.default.post(Notification(name: FocusableNSView<Identifier>.becomeFirstResponderNotification, userInfo: ["id": id]))
    } else {
      NotificationCenter.default.post(Notification(name: FocusableNSView<Identifier>.becomeFirstResponderNotification, userInfo: ["id": "-1"]))
    }
  }

  @Binding var isFocused: Bool
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void
  private let id: Identifier?

  init(id: Identifier,
       isFocused: Binding<Bool>,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.id = id
    _isFocused = isFocused
    self.onKeyDown = onKeyDown
  }

  init(onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) where Identifier == Never {
    _isFocused = .constant(false)
    self.id = nil
    self.onKeyDown = onKeyDown
  }

  func makeNSView(context: Context) -> FocusableNSView<Identifier> {
    FocusableNSView(id, isFocused: $isFocused, onKeyDown: onKeyDown)
  }

  func updateNSView(_ nsView: FocusableNSView<Identifier>, context: Context) { }
}

extension Never.ID: CustomStringConvertible {
  public var description: String { "Never" }
}

class FocusableNSView<Identifier>: NSView where Identifier: Equatable,
                                                Identifier: Hashable,
                                                Identifier: CustomStringConvertible {
  // Re-add the id into the notification so that only one view responds.
  static var becomeFirstResponderNotification: Notification.Name {
    Notification.Name("FocusableNSView.becomeFirstResponder")
  }

  @Binding var isFocused: Bool
  override var canBecomeKeyView: Bool { window != nil }
  override var acceptsFirstResponder: Bool { window != nil }
  fileprivate var id: Identifier?
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void
  private var subscription: AnyCancellable?

  init(_ id: Identifier?,
       isFocused: Binding<Bool>,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    _isFocused = isFocused
    self.id = id
    self.onKeyDown = onKeyDown
    super.init(frame: .zero)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(respondToNotification),
                                           name: Self.becomeFirstResponderNotification, object: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)
    onKeyDown(Int(event.keyCode), event.modifierFlags)
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }

  // MARK: Private methods

  @objc private func respondToNotification(_ notification: Notification) {
    guard let dictionary = (notification.userInfo as? [String: AnyHashable]) else { return }
    guard let id = dictionary["id"] as? Identifier else { return }

    if self.id == id {
      isFocused <- true
      window?.makeFirstResponder(self)
    }
  }
}
