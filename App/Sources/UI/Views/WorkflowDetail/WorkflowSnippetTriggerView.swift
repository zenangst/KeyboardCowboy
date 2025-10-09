import Bonzai
import Inject
import SwiftUI

struct WorkflowSnippetTriggerView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  private var focus: FocusState<AppFocus?>.Binding
  @EnvironmentObject private var snippetController: SnippetController
  @State var snippet: DetailViewModel.SnippetTrigger

  init(_ focus: FocusState<AppFocus?>.Binding,
       snippet: DetailViewModel.SnippetTrigger)
  {
    _snippet = .init(initialValue: snippet)
    self.focus = focus
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
        }, onCommandReturnKey: {
          updater.modifyWorkflow(using: transaction) { workflow in
            workflow.trigger = .snippet(SnippetTrigger(id: snippet.id, text: snippet.text))
          }
        },
      )
      .focused(focus, equals: .detail(.snippet))
    }
    .onDisappear(perform: {
      snippetController.isEnabled = true
    })
    .onChange(of: snippet.text, perform: { _ in
      updater.modifyWorkflow(using: transaction) { workflow in
        workflow.trigger = .snippet(SnippetTrigger(id: snippet.id, text: snippet.text))
      }
    })
    .fixedSize(horizontal: false, vertical: true)
    .roundedStyle()
  }
}

struct WorkflowSnippetTriggerView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static let snippet: DetailViewModel.SnippetTrigger = .init(id: UUID().uuidString, text: "hello world")
  static var previews: some View {
    WorkflowSnippetTriggerView($focus, snippet: snippet)
  }
}
