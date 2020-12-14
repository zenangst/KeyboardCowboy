import SwiftUI
import ModelKit

struct WorkflowConfig {
  var name: String {
    get { workflow.name }
    set { workflow.name = newValue }
  }
  private(set) var workflow: Workflow
}

public struct WorkflowView: View {
  let onUpdate: (WorkflowConfig) -> Void
  @State var config: WorkflowConfig

  init(_ workflow: Workflow, onUpdate: @escaping (WorkflowConfig) -> Void) {
    _config = .init(initialValue: WorkflowConfig(workflow: workflow))
    self.onUpdate = onUpdate
  }

  public var body: some View {
    TextField("", text: $config.name, onCommit: {
      onUpdate(config)
    })
      .font(.largeTitle)
      .foregroundColor(.primary)
      .textFieldStyle(PlainTextFieldStyle())
  }
}

// MARK: Previews

struct WorkflowView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowView(ModelFactory().workflowDetail()) { _  in }
      .frame(height: 200)
  }
}
