import Combine
import Foundation
import SwiftUI

struct ScriptEditorViewable: NSViewRepresentable {
  typealias NSViewType = _ScriptEditorView
  let font: NSFont
  let maxHeight: CGFloat?
  @Binding var text: String
  @Binding var syntax: any SyntaxHighlighting

  init(text: Binding<String>, font: NSFont,
       maxHeight: CGFloat?, syntax: Binding<any SyntaxHighlighting>) {
    _text = text
    _syntax = syntax
    self.font = font
    self.maxHeight = maxHeight
  }

  func makeNSView(context: Context) -> _ScriptEditorView {
    let view = _ScriptEditorView(text, font: font, maxHeight: maxHeight, syntax: syntax)
    context.coordinator.subscribe(to: view.$text)
    context.coordinator.view = view
    return view
  }

  func updateNSView(_ view: _ScriptEditorView, context: Context) {
    if view.syntax.id != syntax.id {
      view.syntax = syntax
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator { view, newText in
      text = newText
    }
  }

  final class Coordinator: NSObject {
    private var subscription: AnyCancellable?
    private let onTextChange: (_ScriptEditorView, String) -> Void
    weak var view: _ScriptEditorView?

    init(onTextChange: @escaping (_ScriptEditorView, String) -> Void) {
      self.onTextChange = onTextChange
    }

    func subscribe(to publisher: Published<String>.Publisher) {
      subscription = publisher
        .dropFirst()
        .sink { [weak self] text in
          guard let self, let view = self.view else { return }
          self.onTextChange(view, text)
      }
    }
  }
}
