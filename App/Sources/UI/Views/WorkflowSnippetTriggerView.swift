import Bonzai
import Inject
import SwiftUI

struct WorkflowSnippetTriggerView: View {
  private var focus: FocusState<AppFocus?>.Binding
  @EnvironmentObject private var snippetController: SnippetController
  @State var snippet: DetailViewModel.SnippetTrigger

  let onUpdate: (DetailViewModel.SnippetTrigger) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       snippet: DetailViewModel.SnippetTrigger,
       onUpdate: @escaping (DetailViewModel.SnippetTrigger) -> Void) {
    _snippet = .init(initialValue: snippet)
    self.focus = focus
    self.onUpdate = onUpdate
  }

  var body: some View {
    HStack(spacing: 4) {
      SnippetIconView(size: 28)
      ZenTextEditor(
        text: $snippet.text,
        placeholder: "Snippet trigger",
        font: Font.system(.body, design: .monospaced),
        onFocusChange: { newValue in
          snippetController.isEnabled = !newValue
        }, onCommandReturnKey: { onUpdate(snippet) }
      )
      .focused(focus, equals: .detail(.snippet))
    }
    .onDisappear(perform: {
        snippetController.isEnabled = true
    })
    .onChange(of: snippet.text, perform: { value in
      onUpdate(snippet)
    })
    .fixedSize(horizontal: false, vertical: true)
    .roundedContainer(padding: 8, margin: 0)
  }
}

struct WorkflowSnippetTriggerView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static let snippet: DetailViewModel.SnippetTrigger = .init(id: UUID().uuidString, text: "hello world")
  static var previews: some View {
    WorkflowSnippetTriggerView($focus, snippet: snippet)  { _ in }
  }
}
