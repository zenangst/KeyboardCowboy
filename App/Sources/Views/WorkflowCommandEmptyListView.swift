import SwiftUI

struct WorkflowCommandEmptyListView: View {
  @Environment(\.openWindow) var openWindow
  @ObservedObject private var detailPublisher: DetailPublisher

  var namespace: Namespace.ID

  init(namespace: Namespace.ID, detailPublisher: DetailPublisher) {
    self.namespace = namespace
    self.detailPublisher = detailPublisher
  }

  var body: some View {
    VStack {
      if detailPublisher.data.commands.isEmpty {
        Button(action: {
          openWindow(value: NewCommandWindow.Context.newCommand(workflowId: detailPublisher.data.id))
        }) {
          HStack {
            Image(systemName: "plus.circle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16, height: 16)
            Divider()
              .opacity(0.5)

            Text("Add a command")
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 8)
        }
        .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen, hoverEffect: false)))
        .matchedGeometryEffect(id: "add-command-button", in: namespace)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

struct WorkflowCommandEmptyListView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandEmptyListView(namespace: namespace, detailPublisher: DesignTime.detailPublisher)
  }
}
