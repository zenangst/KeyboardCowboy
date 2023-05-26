import SwiftUI

struct FocusableProxy<Element>: NSViewRepresentable where Element: Equatable,
                                                          Element: Hashable,
                                                          Element: Identifiable,
                                                          Element.ID: CustomStringConvertible {
  static func post(_ id: Element.ID) {
      NotificationCenter.default.post(Notification(name: FocusableNSView<Element>.becomeFirstResponderNotification, userInfo: ["id": id]))
  }

  @Binding var isFocused: Bool
  private let selectionManager: SelectionManager<Element>
  private let id: Element.ID

  init(_ element: Element,
       isFocused: Binding<Bool>,
       selectionManager: SelectionManager<Element>) {
    self.id = element.id
    self.selectionManager = selectionManager
    _isFocused = isFocused
  }

  func makeNSView(context: Context) -> FocusableNSView<Element> {
    FocusableNSView(id, isFocused: $isFocused, selectionManager: selectionManager)
  }

  func updateNSView(_ nsView: FocusableNSView<Element>, context: Context) { }
}

extension Never.ID: CustomStringConvertible {
  public var description: String { "Never" }
}

class FocusableNSView<Element>: NSView where Element: Equatable,
                                             Element: Hashable,
                                             Element: Identifiable,
                                             Element.ID: CustomStringConvertible {
  // Re-add the id into the notification so that only one view responds.
  static var becomeFirstResponderNotification: Notification.Name {
    Notification.Name("FocusableNSView.becomeFirstResponder")
  }

  var selectionManager: SelectionManager<Element>
  @Binding var isFocused: Bool
  override var canBecomeKeyView: Bool { window != nil }
  override var acceptsFirstResponder: Bool { window != nil }
  fileprivate var id: Element.ID?

  init(_ id: Element.ID, isFocused: Binding<Bool>,
       selectionManager: SelectionManager<Element>) {
    _isFocused = isFocused
    self.id = id
    self.selectionManager = selectionManager
    super.init(frame: .zero)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(respondToNotification),
                                           name: Self.becomeFirstResponderNotification, object: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }

  override func becomeFirstResponder() -> Bool {
    // Guide focus to the first view that matches the id.
    if let lastSelection = selectionManager.lastSelection, lastSelection != id {
      FocusableProxy<Element>.post(lastSelection)
      return false
    }

    return super.becomeFirstResponder()
  }

  // MARK: Private methods

  @objc private func respondToNotification(_ notification: Notification) {
    guard let dictionary = (notification.userInfo as? [String: AnyHashable]) else { return }
    guard let id = dictionary["id"] as? Element.ID else { return }
    guard self.id == id else { return }

    isFocused = true
    selectionManager.setLastSelection(id)
    window?.makeFirstResponder(self)
  }
}
