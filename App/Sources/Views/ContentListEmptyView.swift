import SwiftUI

struct ContentListEmptyView: View {
  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher

  private let namespace: Namespace.ID
  private let onAction: (ContentView.Action) -> Void

  init(_ namespace: Namespace.ID, onAction: @escaping (ContentView.Action) -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
      if groupsPublisher.data.isEmpty {
        Text("Add a group before adding a workflow.")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.systemGray))
      } else if publisher.data.isEmpty {
        VStack(spacing: 8) {
          Button(action: {
            withAnimation {
              onAction(.addWorkflow(workflowId: UUID().uuidString))
            }
          }, label: {
            HStack(spacing: 8) {
              Image(systemName: "plus.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fixedSize()
                .frame(width: 16, height: 16)
              Divider()
                .opacity(0.5)
              Text("Add Workflow")
            }
            .padding(4)
            .matchedGeometryEffect(id: "add-workflow-button", in: namespace, properties: .position)
          })
          .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen, hoverEffect: false)))

          Text("No workflows yet,\nadd a workflow to get started.")
            .multilineTextAlignment(.center)
            .font(.footnote)
            .padding(.top, 8)
        }
        .padding(.top, 128)
      }
  }
}

struct ContentListEmptyView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    ContentListEmptyView(namespace) { _ in }
      .designTime()
  }
}
