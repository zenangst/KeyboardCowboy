import Combine
import SwiftUI

struct ScriptEditorView: View {
  @ObservedObject private var iO = Inject.observer
  @Binding var text: String

  var body: some View {
    ScriptEditorViewable(text: $text)
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
"""))
  }
}
