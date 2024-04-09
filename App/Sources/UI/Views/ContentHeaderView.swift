import Bonzai
import SwiftUI

struct ContentHeaderView: View {
  @EnvironmentObject private var contentPublisher: ContentPublisher
  @EnvironmentObject private var groupPublisher: GroupPublisher

  @Binding private var showAddButton: Bool
  private let namespace: Namespace.ID
  private let onAction: (ContentView.Action) -> Void

  init(namespace: Namespace.ID, 
       showAddButton: Binding<Bool>,
       onAction: @escaping (ContentView.Action) -> Void) {
    _showAddButton = showAddButton
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    ZenLabel("Group", style: .content)
      .padding(.leading, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 6)
    HStack(spacing: 8) {
      GroupIconView(color: groupPublisher.data.color, icon: groupPublisher.data.icon, symbol: groupPublisher.data.symbol)
        .frame(width: 24, height: 24)
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(nsColor: .init(hex: groupPublisher.data.color)).opacity(0.4))
        )
      VStack(alignment: .leading) {
        Text(groupPublisher.data.name)
          .font(.headline)
        Text("Workflows: \(contentPublisher.data.count)")
          .font(.caption)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      ContentAddWorkflowHeaderView(
        namespace,
        isVisible: $showAddButton,
        onAction: { onAction(.addWorkflow(workflowId: UUID().uuidString)) })
    }
    .padding(.bottom, 4)
    .padding(.leading, 14)
    .id(groupPublisher.data)

    ZenLabel("Workflows", style: .content)
      .padding(.leading, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
