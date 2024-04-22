import SwiftUI
import Bonzai

struct WorkflowCommandListHeaderAddView: View {
  @Environment(\.openWindow) var openWindow
  private let namespace: Namespace.ID
  private let workflowId: String

  init(_ namespace: Namespace.ID, workflowId: String) {
    self.namespace = namespace
    self.workflowId = workflowId
  }

  var body: some View {
    Button(action: {
      openWindow(value: NewCommandWindow.Context.newCommand(workflowId: workflowId))
    }) {
      HStack(spacing: 4) {
        Image(systemName: "plus.app")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12, height: 12)
          .padding(2)
          .layoutPriority(-1)
      }
    }
    .help("Add Command")
    .buttonStyle(.zen(.init(color: .systemGreen, grayscaleEffect: .constant(true))))
    .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
  }
}

struct WorkflowCommandListHeaderAddView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandListHeaderAddView(namespace, workflowId: UUID().uuidString)
      .designTime()
      .padding()
  }
}
