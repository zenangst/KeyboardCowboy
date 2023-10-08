import SwiftUI
import ZenViewKit

struct ContentListEmptyView: View {
  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher

  private let namespace: Namespace.ID
  private let onAction: (ContentListView.Action) -> Void

  init(_ namespace: Namespace.ID, onAction: @escaping (ContentListView.Action) -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    Group {
      if groupsPublisher.data.isEmpty {
        Text("Add a group before adding a workflow.")
          .frame(maxWidth: .infinity)
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
          .help("Add Workflow")
          .buttonStyle(.zen(.init(color: .systemGreen, hoverEffect: false)))
          .matchedGeometryEffect(id: "add-workflow-button", in: namespace)

          Text("No workflows yet,\nadd a workflow to get started.")
            .multilineTextAlignment(.center)
            .font(.footnote)
            .padding(.top, 8)
        }
      }
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
