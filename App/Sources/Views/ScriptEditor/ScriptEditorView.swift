import Combine
import SwiftUI

struct ScriptEditorView: View {
  @ObserveInjection var inject
  @FocusState var isFocused: Bool

  @State private var isHovered: Bool = false

  @Binding private var text: String
  @Binding private var syntax: any SyntaxHighlighting
  private let font: NSFont

  init(text: Binding<String>,
       font: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
       syntax: Binding<any SyntaxHighlighting>) {
    _text = text
    self.font = font
    _syntax = syntax
  }

  var body: some View {
    ScriptEditorViewable(
      text: $text, font: font,
      maxHeight: nil,
      syntax: $syntax)
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(isFocused ? .controlAccentColor.withAlphaComponent(0.5) : .windowFrameTextColor), lineWidth: 1)
        .opacity(isFocused ? 0.75 : isHovered ? 0.15 : 0.1)
    )
    .onHover(perform: { newValue in  withAnimation { isHovered = newValue } })
    .focusable()
    .focused($isFocused)
    .enableInjection()
  }
}

struct ScriptEditorView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      ScriptEditorView(text: .constant("""
struct ScriptEditorView: View {
  @State var text: String

  var body: some View {
    ScriptEditorViewable(text: $text)
  }
}
"""),
                       font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                       syntax: .constant(SwiftSyntaxHighlighting()))
    }
  }
}
