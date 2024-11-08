import SwiftUI
import Bonzai

struct EmptyWorkflowList: View {
  @EnvironmentObject private var publisher: GroupDetailPublisher

  private let namespace: Namespace.ID
  private let onAction: (GroupDetailView.Action) -> Void

  init(_ namespace: Namespace.ID, onAction: @escaping (GroupDetailView.Action) -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    Group {
      VStack(spacing: 8) {
        Button(action: {
          withAnimation {
            onAction(.addWorkflow(workflowId: UUID().uuidString))
          }
        }, label: {
          HStack(spacing: 8) {
            Image(systemName: "plus.square.dashed")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .fixedSize()
              .frame(width: 16, height: 16)
            Divider()
              .opacity(0.5)
            Text("Add Workflow")
          }
          .padding(4)
        })
        .fixedSize()
        .help("Add Workflow")
        .buttonStyle(.zen(.init(color: .systemGreen, hoverEffect: .constant(false))))
        .matchedGeometryEffect(id: "add-workflow-button", in: namespace, isSource: false)

        Text("No workflows yet,\nadd a workflow to get started.")
          .multilineTextAlignment(.center)
          .font(.footnote)
          .padding(.top, 8)
      }
      .padding(.top, publisher.data.isEmpty ? 48 : 0)
      .frame(height: publisher.data.isEmpty ? nil : 0)
      .opacity(publisher.data.isEmpty ? 1 : 0)
    }
  }
}

#Preview {
  @Namespace var namespace
  return EmptyWorkflowList(namespace) { _ in }
      .designTime()
      .frame(width: 200, height: 100)
}
