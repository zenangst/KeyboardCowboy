import SwiftUI
import ZenViewKit

struct WorkflowCommandListHeaderAddView: View {
  @EnvironmentObject var detailPublisher: DetailPublisher
  @Environment(\.openWindow) var openWindow
  private let namespace: Namespace.ID

  init(_ namespace: Namespace.ID) {
    self.namespace = namespace
  }

  var body: some View {
    Button(action: {
      openWindow(value: NewCommandWindow.Context.newCommand(workflowId: detailPublisher.data.id))
    }) {
      HStack(spacing: 4) {
        Image(systemName: "plus.app")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 12, maxHeight: 12)
          .padding(2)
          .layoutPriority(-1)
      }
    }
    .help("Add Command")
    .padding(.horizontal, 4)
    .buttonStyle(.zen(.init(color: .systemGreen, grayscaleEffect: .constant(true))))
    .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
  }
}

struct WorkflowCommandListHeaderAddView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandListHeaderAddView(namespace)
      .designTime()
      .padding()
  }
}
