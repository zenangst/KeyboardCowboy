import SwiftUI

struct WorkflowCommandListHeaderAddView: View {
  @EnvironmentObject var detailPublisher: DetailPublisher
  @Environment(\.openWindow) var openWindow
  private let namespace: Namespace.ID

  init(_ namespace: Namespace.ID) {
    self.namespace = namespace
  }

  var body: some View {
    if !detailPublisher.data.commands.isEmpty {
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
      .padding(.horizontal, 4)
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
      .matchedGeometryEffect(id: "add-command-button", in: namespace, properties: .position)
    }

  }
}
