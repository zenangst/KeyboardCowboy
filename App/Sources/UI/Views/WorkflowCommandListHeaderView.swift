import SwiftUI

struct WorkflowCommandListHeaderView: View {
  @EnvironmentObject var detailPublisher: DetailPublisher
  @Environment(\.openWindow) var openWindow
  let namespace: Namespace.ID

  init(namespace: Namespace.ID, onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.namespace = namespace
    self.onAction = onAction
  }

  private let onAction: (SingleDetailView.Action) -> Void

  var body: some View {
    HStack {
      Label("Commands", image: "")
      Spacer()
      Menu(content: {
        ForEach(DetailViewModel.Execution.allCases) { execution in
          Button(execution.rawValue, action: {
            onAction(.updateExecution(workflowId: detailPublisher.data.id,
                                      execution: execution))
          })
        }
      }, label: {
        Image(systemName: "play.fill")
        Text("Run \(detailPublisher.data.execution.rawValue)")
      }, primaryAction: {
        onAction(.runWorkflow(workflowId: detailPublisher.data.id))
      })
      .padding(.horizontal, 2)
      .padding(.top, 3)
      .padding(.bottom, 1)
      .overlay(alignment: .trailing, content: {
        Rectangle()
          .fill(Color(.white).opacity(0.2))
          .frame(width: 1)
          .padding(.horizontal, 18)
          .padding(.vertical, 4)
          .offset(x: -4, y: 1)
      })
      .menuStyle(AppMenuStyle(.init(nsColor: .systemGray), menuIndicator: .visible))
      .frame(maxWidth: detailPublisher.data.execution == .concurrent ? 144 : 110,
             alignment: .leading)
      .opacity(detailPublisher.data.commands.isEmpty ? 0 : 1)

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
    .padding(.horizontal)
  }
}
