import Combine
import SwiftUI

struct ScriptEditorView: View {
  @ObserveInjection var inject
  @Binding var text: String
  let syntax: SyntaxHighlighting

  var body: some View {
    ScriptEditorViewable(text: $text, syntax: syntax)
      .enableInjection()
  }
}

struct ScriptEditorView_Previews: PreviewProvider {
  static var previews: some View {
    ScriptEditorView(text: .constant("""
struct ScriptEditorView: View {
  @State var text: String

  var body: some View {
    ScriptEditorViewable(text: $text)
  }
}
"""), syntax: SwiftSyntaxHighlighting())
  }
}
