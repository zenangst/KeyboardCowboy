import Cocoa
import Combine
import SwiftUI

class KeyboardShortcutRecorderView: NSSearchField {
  typealias OnCommit = (KeyboardShortcutViewModel?) -> Void

  @State private var keyboardShortcut: KeyboardShortcutViewModel?
  private var cancellables = Set<AnyCancellable>()
  private let viewController: KeyboardShortcutRecorderViewController
  private let onCommit: OnCommit

  required init(keyboardShortcut: KeyboardShortcutViewModel?,
                placeholder: String? = nil,
                onCommit: @escaping OnCommit) {
    self.keyboardShortcut = keyboardShortcut
    self.viewController = KeyboardShortcutRecorderViewController(identifier: keyboardShortcut?.id ?? UUID().uuidString)
    self.onCommit = onCommit
    super.init(frame: .zero)
    self.placeholderString = placeholder
    self.centersPlaceholder = true
    self.alignment = .center
    self.delegate = viewController
    (self.cell as? NSSearchFieldCell)?.searchButtonCell = nil
    self.update(keyboardShortcut)

    self.viewController.onCommit = { keyboardShortcut in
      self.update(keyboardShortcut)
      self.onCommit(keyboardShortcut)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func update(_ keyboardShortcut: KeyboardShortcutViewModel?) {
    guard let keyboardShortcut = keyboardShortcut else {
      stringValue = ""
      return
    }

    var newValue = keyboardShortcut.modifiers.compactMap({ $0.pretty }).joined()
    newValue += keyboardShortcut.key

    stringValue = newValue
  }

  override func becomeFirstResponder() -> Bool {
    viewController.didBecomeFirstResponder()
    return true
  }
}

struct Recorder: NSViewRepresentable {
  typealias OnCommit = (KeyboardShortcutViewModel?) -> Void
  typealias NSViewType = KeyboardShortcutRecorderView

  @Binding var keyboardShortcut: KeyboardShortcutViewModel?

  func makeNSView(context: Context) -> KeyboardShortcutRecorderView {
    KeyboardShortcutRecorderView(keyboardShortcut: keyboardShortcut,
                                 placeholder: "Record Keyboard Shortcut",
                                 onCommit: {
                                  keyboardShortcut = $0
                                 })
  }

  func updateNSView(_ nsView: KeyboardShortcutRecorderView, context: Context) {}
}

// MARK: - Previews

struct Recorder_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      Recorder(keyboardShortcut: .constant(nil))
      Recorder(keyboardShortcut: .constant(KeyboardShortcutViewModel(index: 1, key: "F",
                                                                     modifiers: [.command, .option])))
    }
  }
}
