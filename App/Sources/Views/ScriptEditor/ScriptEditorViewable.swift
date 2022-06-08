import Foundation
import SwiftUI

struct ScriptEditorViewable: NSViewRepresentable {
  typealias NSViewType = _ScriptEditorView
  @Binding var text: String
  let syntax: SyntaxHighlighting

  init(text: Binding<String>, syntax: SyntaxHighlighting) {
    _text = text
    self.syntax = syntax
  }

  func makeNSView(context: Context) -> _ScriptEditorView {
    let view = _ScriptEditorView(text, syntax: syntax)
    view.textView.delegate = context.coordinator
    view.autoresizesSubviews = true
    view.autoresizingMask = [.width]
    context.coordinator.scriptView = view
    return view
  }

  func updateNSView(_ view: _ScriptEditorView, context: Context) {
    view.updateTextStorage(text)
    view.selectedRanges = context.coordinator.selectedRanges
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    var view: ScriptEditorViewable
    var selectedRanges: [NSValue] = []
    weak var scriptView: _ScriptEditorView?

    init(_ view: ScriptEditorViewable) {
      self.view = view
    }

    func textViewDidChangeSelection(_ notification: Notification) {
      guard notification.object is NSTextView else { return }
      guard let scriptView = scriptView else { return }

      scriptView.updateCursorPosition()
    }

    public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?
    ) -> Bool {
      guard let scriptView = scriptView else {
        return true
      }

      guard let replacementString = replacementString else {
        scriptView.currentInput = ""
        return true
      }

      let illegalChars = [" ", "\n"]
      if replacementString.count == 1 &&
         !illegalChars.contains(replacementString) {
        scriptView.currentInput += replacementString
      } else {
        scriptView.currentInput = ""
      }

      return true
    }

    public func textDidBeginEditing(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }

      view.text = textView.string
    }

    public func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      let content = String(textView.textStorage?.string ?? "")

      view.text = content
      selectedRanges = textView.selectedRanges
    }

    public func textDidEndEditing(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }

      view.text = textView.string
    }
  }
}
