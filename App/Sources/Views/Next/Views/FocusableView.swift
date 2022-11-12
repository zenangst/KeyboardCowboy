import SwiftUI
import Carbon

struct FocusableView<Content>: View where Content: View {
  @ObserveInjection var inject
  @Binding var isFocused: Bool

  private let id: CustomStringConvertible
  private var content: () -> Content
  private var onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(id: CustomStringConvertible,
       isFocused: Binding<Bool>,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void,
       content: @escaping () -> Content) {
    _isFocused = isFocused
    self.id = id
    self.content = content
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    VStack {
      content()
        .background(
          FocusableProxy(
            id: id,
            onFocusChange: { isFocused = $0 },
            onKeyDown: onKeyDown)
        )
    }
  }
}

private struct FocusableProxy: NSViewRepresentable {
  typealias NSViewType = FocusableNSView

  private let id: CustomStringConvertible
  private let onFocusChange: (Bool) -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(id: CustomStringConvertible,
       onFocusChange: @escaping (Bool) -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.id = id
    self.onFocusChange = onFocusChange
    self.onKeyDown = onKeyDown
  }

  func makeNSView(context: Context) -> FocusableNSView {
    FocusableNSView(id: id, onFocusChange: onFocusChange, onKeyDown: onKeyDown)
  }

  func updateNSView(_ nsView: FocusableNSView, context: Context) { }
}

class FocusableNSView: NSView {
  static func becomeFirstResponderNotification(_ id: CustomStringConvertible) -> Notification.Name {
    Notification.Name("FocusableNSView[\(id)].becomeFirstResponder")
  }

  override var canBecomeKeyView: Bool { true }
  override var acceptsFirstResponder: Bool { true }
  private let id: CustomStringConvertible
  private let onFocusChange: (Bool) -> Void
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(id: CustomStringConvertible,
       onFocusChange: @escaping (Bool) -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.id = id
    self.onFocusChange = onFocusChange
    self.onKeyDown = onKeyDown
    super.init(frame: .zero)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(becomeFirstResponder),
                                           name: Self.becomeFirstResponderNotification(id), object: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func becomeFirstResponder() -> Bool {
    let value = super.becomeFirstResponder()
    onFocusChange(true)
    return value
  }

  override func resignFirstResponder() -> Bool {
    let value = super.resignFirstResponder()
    onFocusChange(false)
    return value
  }

  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)
    onKeyDown(Int(event.keyCode), event.modifierFlags)
  }
}
