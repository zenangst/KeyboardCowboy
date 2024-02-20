import Bonzai
import Inject
import SwiftUI

struct WorkflowSnippetTriggerView: View {
  @EnvironmentObject var snippetController: SnippetController
  @ObserveInjection var inject
  @State var snippet: DetailViewModel.SnippetTrigger

  let onUpdate: (DetailViewModel.SnippetTrigger) -> Void

  init(_ snippet: DetailViewModel.SnippetTrigger,
       onUpdate: @escaping (DetailViewModel.SnippetTrigger) -> Void) {
    _snippet = .init(initialValue: snippet)
    self.onUpdate = onUpdate
  }

  var body: some View {
    ZenTextEditor(
      text: $snippet.text,
      placeholder: "Snippet trigger",
      font: Font.system(.body, design: .monospaced),
      onFocusChange: { newValue in
        snippetController.isEnabled = !newValue
      }, onCommandReturnKey: { onUpdate(snippet) }
    )
    .onChange(of: snippet.text, perform: { value in
      onUpdate(snippet)
    })
    .fixedSize(horizontal: false, vertical: true)
    .roundedContainer(padding: 8, margin: 0)
    .enableInjection()
  }
}

struct WorkflowSnippetTriggerView_Previews: PreviewProvider {
    static var previews: some View {
      WorkflowSnippetTriggerView(
        .init(id: UUID().uuidString, text: "hello world")
      )  { _ in }
    }
}
