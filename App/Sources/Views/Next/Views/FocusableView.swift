import SwiftUI
import Carbon

struct FocusableView<Content>: View where Content: View {
  @ObserveInjection var inject
  @Binding var isFocused: Bool

  private var content: () -> Content
  private var onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(_ isFocused: Binding<Bool>,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void,
       content: @escaping () -> Content) {
    _isFocused = isFocused
    self.content = content
    self.onKeyDown = onKeyDown
  }

  var body: some View {
    VStack {
      content()
        .background(
          FocusableProxy(
            onFocusChange: { isFocused = $0 },
            onKeyDown: onKeyDown)
        )
    }
  }
}

private struct FocusableProxy: NSViewRepresentable {
  typealias NSViewType = FocusableNSView

  var onFocusChange: (Bool) -> Void
  var onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(onFocusChange: @escaping (Bool) -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.onFocusChange = onFocusChange
    self.onKeyDown = onKeyDown
  }

  func makeNSView(context: Context) -> FocusableNSView {
    FocusableNSView(onFocusChange: onFocusChange,
                    onKeyDown: onKeyDown)
  }

  func updateNSView(_ nsView: FocusableNSView, context: Context) { }
}

private class FocusableNSView: NSView {
  override var canBecomeKeyView: Bool { true }
  override var acceptsFirstResponder: Bool { true }
  var onFocusChange: (Bool) -> Void
  var onKeyDown: (Int, NSEvent.ModifierFlags) -> Void

  init(onFocusChange: @escaping (Bool) -> Void,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.onFocusChange = onFocusChange
    self.onKeyDown = onKeyDown
    super.init(frame: .zero)
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
