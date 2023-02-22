import SwiftUI
import Combine

struct FocusableProxy<Element>: NSViewRepresentable where Element: Identifiable,
                                                          Element: Hashable,
                                                          Element.ID: CustomStringConvertible {
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void
  private let element: Element?

  init(element: Element,
       onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.element = element
    self.onKeyDown = onKeyDown
  }

  init(onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) where Element == Never {
    self.element = nil
    self.onKeyDown = onKeyDown
  }

  func makeNSView(context: Context) -> FocusableNSView<Element> { FocusableNSView(element, onKeyDown: onKeyDown) }
  func updateNSView(_ nsView: FocusableNSView<Element>, context: Context) { }
}

extension Never.ID: CustomStringConvertible {
  public var description: String { "Never" }
}

class FocusableNSView<Element>: NSView where Element: Identifiable,
                                             Element: Hashable,
                                             Element.ID: CustomStringConvertible {
  override var canBecomeKeyView: Bool { true }
  override var acceptsFirstResponder: Bool { true }
  fileprivate var element: Element?
  private let onKeyDown: (Int, NSEvent.ModifierFlags) -> Void
  private var subscription: AnyCancellable?

  init(_ element: Element?, onKeyDown: @escaping (Int, NSEvent.ModifierFlags) -> Void) {
    self.element = element
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

  override func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }
}
